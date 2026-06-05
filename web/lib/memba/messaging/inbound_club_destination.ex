defmodule Memba.Messaging.InboundClubDestination do
  @moduledoc """
  Resolved destination for a provider-neutral inbound club-message email.

  The current slice supports one whole-club inbound address shape:
  `<club-slug>@<configured inbound domain>`. Resolution deliberately uses
  Membership's public slug lookup API so Messaging does not couple to
  Membership projection internals.
  """

  alias Memba.ClubInboundEmailAddress
  alias Memba.Membership
  alias Memba.Membership.Slug
  alias Memba.Messaging.InboundEmail

  @enforce_keys [:club_id, :club_slug, :club_name, :to_address]
  defstruct [:club_id, :club_slug, :club_name, :to_address]

  @type t :: %__MODULE__{
          club_id: String.t(),
          club_slug: String.t(),
          club_name: String.t(),
          to_address: String.t()
        }

  @type rejection_reason :: :unsupported_recipient_address | :unknown_club_slug
  @type rejection :: {:error, rejection_reason(), String.t() | nil}

  @doc """
  Resolve recipient addresses to the destination club for an inbound email.

  Returns `{:ok, destination}` when any recipient address uses the configured
  inbound club domain and its local part matches an existing club slug. Unrelated
  copied recipients are ignored once a supported club destination is found.

  Returns `{:error, :unknown_club_slug, to_address}` when the inbound domain is
  present but no matching club exists, or
  `{:error, :unsupported_recipient_address, address_or_nil}` when no supported
  whole-club address shape is present.
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
         {:ok, local_part, domain} <- split_address(normalized_address),
         true <- domain == ClubInboundEmailAddress.domain(),
         {:ok, slug} <- Slug.normalize_for_lookup(local_part) do
      {:club_candidate, slug, normalized_address}
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
      [local_part, domain] when local_part != "" and domain != "" ->
        {:ok, local_part, domain}

      _parts ->
        {:error, :invalid_address}
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
    |> Enum.reduce(%{destination: nil, unknown: nil, unsupported: nil}, &accumulate_candidate/2)
    |> resolve_accumulator()
  end

  defp accumulate_candidate(_candidate, %{destination: %__MODULE__{}} = accumulator),
    do: accumulator

  defp accumulate_candidate({:club_candidate, slug, to_address}, accumulator) do
    case Membership.get_club_by_slug(slug) do
      nil -> record_first(accumulator, :unknown, to_address)
      club -> %{accumulator | destination: destination(club, to_address)}
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

  defp resolve_accumulator(%{destination: %__MODULE__{} = destination}), do: {:ok, destination}

  defp resolve_accumulator(%{unknown: to_address}) when is_binary(to_address) do
    {:error, :unknown_club_slug, to_address}
  end

  defp resolve_accumulator(%{unsupported: address}) do
    {:error, :unsupported_recipient_address, address}
  end

  defp destination(club, to_address) do
    %__MODULE__{
      club_id: club.club_id,
      club_slug: club.slug,
      club_name: club.name,
      to_address: to_address
    }
  end
end
