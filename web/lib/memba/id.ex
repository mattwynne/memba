defmodule Memba.ID do
  @moduledoc """
  Stripe-style typed identifiers for Memba domain entities.

  IDs are stored and exchanged as strings with a three-character prefix, an
  underscore, and a UUID payload, e.g. `clb_550e8400-e29b-41d4-a716-446655440000`.
  """

  @prefixes %{
    club: "clb",
    club_invitation: "inv",
    group: "grp",
    person: "per",
    role: "rol",
    membership: "mem",
    message: "msg",
    delivery: "del",
    conversation_follow: "cfl",
    inbound_email: "inb",
    email_address: "ead",
    onboarding_request: "req",
    auth_email_request: "aer"
  }

  @types Map.keys(@prefixes)

  @type type ::
          :club
          | :club_invitation
          | :group
          | :person
          | :role
          | :membership
          | :message
          | :delivery
          | :conversation_follow
          | :inbound_email
          | :email_address
          | :onboarding_request
          | :auth_email_request
  @type t :: String.t()

  @doc "Generate a new typed ID."
  @spec generate(type()) :: t()
  def generate(type) when type in @types do
    "#{Map.fetch!(@prefixes, type)}_#{Ecto.UUID.generate()}"
  end

  @doc "Generate a deterministic typed ID from source parts."
  @spec deterministic(type(), [String.t()]) :: t()
  def deterministic(type, parts) when type in @types and is_list(parts) do
    uuid =
      parts
      |> Enum.join(<<0>>)
      |> then(&:crypto.hash(:md5, &1))
      |> Base.encode16(case: :lower)
      |> format_uuid()

    "#{Map.fetch!(@prefixes, type)}_#{uuid}"
  end

  @doc "Cast a value to the expected typed ID."
  @spec cast(type(), term()) :: {:ok, t()} | :error
  def cast(type, value) when type in @types and is_binary(value) do
    prefix = Map.fetch!(@prefixes, type)

    with [^prefix, uuid] <- String.split(value, "_", parts: 2),
         {:ok, ^uuid} <- Ecto.UUID.cast(uuid) do
      {:ok, value}
    else
      _other -> :error
    end
  end

  def cast(type, _value) when type in @types, do: :error

  defp format_uuid(
         <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4),
           e::binary-size(12)>>
       ) do
    Enum.join([a, b, c, d, e], "-")
  end

  @doc "Return whether a value is a valid ID of the expected type."
  @spec valid?(type(), term()) :: boolean()
  def valid?(type, value) when type in @types do
    match?({:ok, _id}, cast(type, value))
  end
end
