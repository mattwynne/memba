defmodule Memba.Accounts.SignInToken do
  @moduledoc """
  Ecto schema for persisted sign-in-link authentication tokens.

  Token plaintext is never stored. `token_hash` contains the SHA-256 digest of
  the opaque token delivered to the user.
  """

  use Ecto.Schema

  import Ecto.Changeset

  schema "auth_sign_in_tokens" do
    field :email, :string
    field :token_hash, :binary
    field :expires_at, :utc_datetime_usec
    field :consumed_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end

  def create_changeset(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> change(attrs)
    |> validate_required([:email, :token_hash, :expires_at])
  end

  def consume_changeset(%__MODULE__{} = sign_in_token, consumed_at) do
    sign_in_token
    |> change(consumed_at: consumed_at)
    |> validate_required([:consumed_at])
  end
end
