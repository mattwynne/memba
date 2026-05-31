defmodule Memba.Accounts.MagicToken do
  @moduledoc """
  Persistence schema for one-time email magic-link authentication tokens.

  Only the token hash is stored. The raw token is generated and shown to the
  user once by the Accounts context, then discarded.
  """

  use Ecto.Schema

  @derive {Inspect, except: [:token_hash]}
  @primary_key {:magic_token_id, :binary_id, autogenerate: true}
  schema "accounts_magic_tokens" do
    field :email, :string
    field :token_hash, :binary
    field :expires_at, :utc_datetime_usec
    field :consumed_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end
end
