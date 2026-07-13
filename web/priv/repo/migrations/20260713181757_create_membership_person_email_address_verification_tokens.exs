defmodule Memba.Repo.Migrations.CreateMembershipPersonEmailAddressVerificationTokens do
  use Ecto.Migration

  def change do
    create table(:membership_person_email_address_verification_tokens) do
      add :person_id,
          references(:membership_people,
            column: :person_id,
            type: :text,
            on_delete: :delete_all
          ),
          null: false

      add :normalized_email, :text, null: false
      add :token_hash, :binary, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :consumed_at, :utc_datetime_usec
      add :revoked_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:membership_person_email_address_verification_tokens, [:token_hash],
             name: :membership_person_email_address_verification_tokens_token_hash_index
           )

    create index(
             :membership_person_email_address_verification_tokens,
             [:person_id, :normalized_email],
             name: :membership_person_email_address_verification_tokens_person_email_index
           )

    create index(:membership_person_email_address_verification_tokens, [:expires_at],
             name: :membership_person_email_address_verification_tokens_expires_at_index
           )
  end
end
