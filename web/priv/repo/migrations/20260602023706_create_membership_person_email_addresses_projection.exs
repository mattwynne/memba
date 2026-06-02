defmodule Memba.Repo.Migrations.CreateMembershipPersonEmailAddressesProjection do
  use Ecto.Migration

  def change do
    create table(:membership_person_email_addresses, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :person_id,
          references(:membership_people,
            column: :person_id,
            type: :uuid,
            on_delete: :delete_all
          )

      add :email, :text
      add :normalized_email, :text
      add :is_primary, :boolean, null: false, default: false

      timestamps(type: :utc_datetime_usec)
    end
  end
end
