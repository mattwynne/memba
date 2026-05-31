defmodule Memba.Repo.Migrations.CreateAccountsMagicTokens do
  use Ecto.Migration

  def change do
    create table(:accounts_magic_tokens, primary_key: false) do
      add :magic_token_id, :uuid, primary_key: true
      add :email, :text, null: false
      add :token_hash, :binary, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :consumed_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:accounts_magic_tokens, [:token_hash])
    create index(:accounts_magic_tokens, [:email])
    create index(:accounts_magic_tokens, [:expires_at])
  end
end
