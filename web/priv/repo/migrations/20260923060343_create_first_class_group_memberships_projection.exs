defmodule Memba.Repo.Migrations.CreateFirstClassGroupMembershipsProjection do
  use Ecto.Migration

  def change do
    create table(:membership_first_class_group_memberships, primary_key: false) do
      add :group_membership_id, :text, primary_key: true
      add :club_id, :text, null: false
      add :group_id, :text, null: false
      add :membership_id, :text, null: false
      add :person_id, :text, null: false
      add :active, :boolean, null: false
      add :end_idempotency_key, :text
      add :end_reason, :text
    end

    create unique_index(
             :membership_first_class_group_memberships,
             [:group_id, :membership_id],
             where: "active",
             name: :membership_fc_group_memberships_current_pair_idx
           )

    create index(
             :membership_first_class_group_memberships,
             [:club_id, :person_id],
             where: "active",
             name: :membership_fc_group_memberships_club_person_idx
           )

    create constraint(
             :membership_first_class_group_memberships,
             :membership_fc_group_memberships_lifecycle_check,
             check: """
             (active AND end_idempotency_key IS NULL AND end_reason IS NULL)
             OR
             (NOT active AND end_idempotency_key IS NOT NULL AND end_reason IS NOT NULL)
             """
           )
  end
end
