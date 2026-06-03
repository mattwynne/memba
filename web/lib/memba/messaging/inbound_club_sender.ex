defmodule Memba.Messaging.InboundClubSender do
  @moduledoc """
  Resolved sender for a provider-neutral inbound club-message email.

  Sender resolution deliberately uses Membership's public email lookup API so
  Messaging can identify people by primary or alternate email address without
  coupling to Membership projection storage.
  """

  alias Memba.Membership
  alias Memba.Messaging.InboundEmail

  @enforce_keys [:person_id, :name, :from_address]
  defstruct [:person_id, :name, :from_address]

  @type t :: %__MODULE__{
          person_id: Ecto.UUID.t(),
          name: String.t(),
          from_address: String.t()
        }

  @type rejection_reason :: :unknown_sender
  @type rejection :: {:error, rejection_reason(), String.t() | nil}

  @doc """
  Resolve an inbound email sender address to a Membership person.

  Returns `{:ok, sender}` when the address belongs to a person as either their
  primary or alternate email address. Returns `{:error, :unknown_sender,
  normalized_address_or_nil}` for blank, invalid, or unknown sender input.
  """
  @spec resolve(InboundEmail.t() | String.t() | term()) :: {:ok, t()} | rejection()
  def resolve(%InboundEmail{from_address: from_address}), do: resolve(from_address)

  def resolve(from_address) do
    case normalize_address(from_address) do
      {:ok, normalized_address} ->
        resolve_normalized_address(normalized_address)

      {:error, :blank_address} ->
        {:error, :unknown_sender, nil}

      {:error, :invalid_address} ->
        {:error, :unknown_sender, nil}
    end
  end

  defp normalize_address(address) when is_binary(address) do
    case address |> String.trim() |> String.downcase() do
      "" -> {:error, :blank_address}
      normalized_address -> {:ok, normalized_address}
    end
  end

  defp normalize_address(_address), do: {:error, :invalid_address}

  defp resolve_normalized_address(normalized_address) do
    case Membership.get_person_by_email(normalized_address) do
      nil ->
        {:error, :unknown_sender, normalized_address}

      person ->
        {:ok,
         %__MODULE__{
           person_id: person.person_id,
           name: person.name,
           from_address: normalized_address
         }}
    end
  end
end
