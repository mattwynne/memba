defmodule Memba.Repo.Migrations.AddConstraintsToMembershipPersonEmailAddresses do
  use Ecto.Migration

  def change do
    alter table(:membership_person_email_addresses) do
      modify :person_id, :uuid, null: false
      modify :email, :text, null: false
      modify :normalized_email, :text, null: false
    end

    create unique_index(:membership_person_email_addresses, [:normalized_email],
             name: :membership_person_email_addresses_normalized_email_index
           )

    create unique_index(:membership_person_email_addresses, [:person_id],
             name: :membership_person_email_addresses_one_primary_per_person_index,
             where: "is_primary = true"
           )
  end
end
