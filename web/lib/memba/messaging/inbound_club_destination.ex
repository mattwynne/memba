defmodule Memba.Messaging.InboundClubDestination do
  @moduledoc """
  Resolved destination for a provider-neutral inbound club-message email.

  Addresses use the shape
  `<group-email-slug>@<club-slug>.<configured inbound domain>`. Resolution
  deliberately uses Membership's public club and group lookup APIs so Messaging
  does not couple to Membership projection internals.
  """

  alias Memba.ClubInboundEmailAddress
  alias Memba.Membership
  alias Memba.Membership.Slug
  alias Memba.Messaging.InboundEmail

  @enforce_keys [
    :club_id,
    :club_slug,
    :club_name,
    :group_id,
    :group_email_slug,
    :group_name,
    :to_address
  ]
  defstruct [
    :club_id,
    :club_slug,
    :club_name,
    :group_id,
    :group_email_slug,
    :group_name,
    :to_address
  ]

  @type t :: %__MODULE__{
          club_id: String.t(),
          club_slug: String.t(),
          club_name: String.t(),
          group_id: String.t(),
          group_email_slug: String.t(),
          group_name: String.t(),
          to_address: String.t()
        }

  @type rejection_reason :: :unsupported_recipient_address | :unknown_club_slug
  @type rejection :: {:error, rejection_reason(), String.t() | nil}

  @doc """
  Resolve recipient addresses to the destination club and group for an inbound email.

  Returns `{:ok, destination}` when any recipient address uses the supported
  `<group-email-slug>@<club-slug>` shape under the configured inbound domain and
  both slugs match projected Membership records. Unrelated copied recipients are
  ignored once a supported group destination is found.

  Returns `{:error, :unknown_club_slug, to_address}` when a supported subdomain
  address is present but no matching club exists. A valid but unknown group slug
  in a known club retains the existing
  `{:error, :unsupported_recipient_address, to_address}` outcome. Other
  unsupported inputs return the same reason with the first relevant address, or
  with `nil` when no usable address is present.
  """
  @spec resolve(InboundEmail.t() | [String.t()] | term()) :: {:ok, t()} | rejection()
  def resolve(%InboundEmail{recipient_addresses: recipient_addresses}),
    do: resolve(recipient_addresses)

  def resolve(recipient_addresses) when is_list(recipient_addresses) do
    recipient_addresses
    |> Enum.map(&candidate/1)
    |> resolve_candidates()
  end

  def resolve(_recipient_addresses), do: {:error, :unsupported_recipient_address, nil}

  defp candidate(address) do
    with {:ok, normalized_address} <- normalize_address(address),
         {:ok, local_part, host} <- split_address(normalized_address),
         {:ok, club_slug, group_email_slug} <- resolve_destination_slugs(local_part, host) do
      {:destination_candidate, club_slug, group_email_slug, normalized_address}
    else
      {:error, _reason} -> unsupported_candidate(address)
      false -> unsupported_candidate(address)
    end
  end

  defp normalize_address(address) when is_binary(address) do
    case address |> String.trim() |> String.downcase() do
      "" -> {:error, :blank_address}
      normalized_address -> {:ok, normalized_address}
    end
  end

  defp normalize_address(_address), do: {:error, :invalid_address}

  defp split_address(address) do
    case String.split(address, "@") do
      [local_part, host] when local_part != "" and host != "" ->
        {:ok, local_part, host}

      _parts ->
        {:error, :invalid_address}
    end
  end

  defp resolve_destination_slugs(local_part, host) do
    case club_slug_from_subdomain_host(host) do
      {:ok, club_slug} ->
        with {:ok, group_email_slug} <- Slug.normalize_for_lookup(local_part) do
          {:ok, club_slug, group_email_slug}
        end

      {:error, :not_club_subdomain_host} ->
        {:error, :unsupported_recipient_address}

      {:error, _reason} = error ->
        error
    end
  end

  defp club_slug_from_subdomain_host(host) do
    inbound_domain = ClubInboundEmailAddress.domain()
    subdomain_suffix = "." <> inbound_domain

    cond do
      host == inbound_domain ->
        {:error, :not_club_subdomain_host}

      String.ends_with?(host, subdomain_suffix) ->
        host
        |> String.replace_suffix(subdomain_suffix, "")
        |> Slug.normalize_for_lookup()

      true ->
        {:error, :not_club_subdomain_host}
    end
  end

  defp unsupported_candidate(address) do
    case normalize_address(address) do
      {:ok, normalized_address} -> {:unsupported, normalized_address}
      {:error, _reason} -> {:unsupported, nil}
    end
  end

  defp resolve_candidates(candidates) do
    candidates
    |> Enum.reduce(
      %{destination: nil, unknown_club: nil, unknown_group: nil, unsupported: nil},
      &accumulate_candidate/2
    )
    |> resolve_accumulator()
  end

  defp accumulate_candidate(_candidate, %{destination: %__MODULE__{}} = accumulator),
    do: accumulator

  defp accumulate_candidate(
         {:destination_candidate, club_slug, group_email_slug, to_address},
         accumulator
       ) do
    case Membership.get_club_by_slug(club_slug) do
      nil -> record_first(accumulator, :unknown_club, to_address)
      club -> resolve_group_candidate(accumulator, club, group_email_slug, to_address)
    end
  end

  defp accumulate_candidate({:unsupported, address}, accumulator) do
    record_first(accumulator, :unsupported, address)
  end

  defp record_first(accumulator, key, value) do
    if Map.fetch!(accumulator, key) do
      accumulator
    else
      Map.put(accumulator, key, value)
    end
  end

  defp resolve_group_candidate(accumulator, club, group_email_slug, to_address) do
    case Membership.get_group_by_email_slug(club.club_id, group_email_slug) do
      nil -> record_first(accumulator, :unknown_group, to_address)
      group -> %{accumulator | destination: destination(club, group, to_address)}
    end
  end

  defp resolve_accumulator(%{destination: %__MODULE__{} = destination}), do: {:ok, destination}

  defp resolve_accumulator(%{unknown_club: to_address}) when is_binary(to_address) do
    {:error, :unknown_club_slug, to_address}
  end

  defp resolve_accumulator(%{unknown_group: to_address}) when is_binary(to_address) do
    {:error, :unsupported_recipient_address, to_address}
  end

  defp resolve_accumulator(%{unsupported: address}) do
    {:error, :unsupported_recipient_address, address}
  end

  defp destination(club, group, to_address) do
    %__MODULE__{
      club_id: club.club_id,
      club_slug: club.slug,
      club_name: club.name,
      group_id: group.group_id,
      group_email_slug: group.email_slug,
      group_name: group.name,
      to_address: to_address
    }
  end
end
