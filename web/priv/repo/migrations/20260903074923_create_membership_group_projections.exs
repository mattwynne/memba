defmodule Memba.Repo.Migrations.CreateMembershipGroupProjections do
  use Ecto.Migration

  def change do
    create table(:membership_groups, primary_key: false) do
      add :group_id, :text, primary_key: true
      add :club_id, :text, null: false
      add :group_key, :text
      add :name, :text, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:membership_groups, [:club_id])

    create unique_index(:membership_groups, [:club_id, :group_key],
             where: "group_key IS NOT NULL"
           )

    create table(:membership_group_memberships, primary_key: false) do
      add :club_id, :text, null: false
      add :group_id, :text, null: false
      add :membership_id, :text, null: false
      add :person_id, :text, null: false
      add :active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime_usec)
    end

    create index(:membership_group_memberships, [:club_id, :group_id], where: "active")
    create index(:membership_group_memberships, [:club_id, :person_id], where: "active")
    create index(:membership_group_memberships, [:membership_id], where: "active")
    create unique_index(:membership_group_memberships, [:group_id, :membership_id])
  end
end
