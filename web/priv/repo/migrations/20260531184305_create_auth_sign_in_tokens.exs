defmodule Memba.Repo.Migrations.CreateAuthSignInTokens do
  use Ecto.Migration

  def change do
    create table(:auth_sign_in_tokens) do
      add :email, :text, null: false
      add :token_hash, :binary, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :consumed_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:auth_sign_in_tokens, [:token_hash])
    create index(:auth_sign_in_tokens, [:email])
    create index(:auth_sign_in_tokens, [:expires_at])
  end
end
