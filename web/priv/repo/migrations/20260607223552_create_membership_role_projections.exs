defmodule Memba.Repo.Migrations.CreateMembershipRoleProjections do
  use Ecto.Migration

  def change do
    create table(:membership_roles, primary_key: false) do
      add :role_id, :text, primary_key: true
      add :club_id, :text, null: false
      add :role_key, :text
      add :name, :text, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:membership_roles, [:club_id])
    create unique_index(:membership_roles, [:club_id, :role_key], where: "role_key IS NOT NULL")

    create table(:membership_role_permissions, primary_key: false) do
      add :club_id, :text, null: false
      add :role_id, :text, null: false
      add :permission, :text, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:membership_role_permissions, [:club_id])
    create index(:membership_role_permissions, [:permission])
    create unique_index(:membership_role_permissions, [:role_id, :permission])

    create table(:membership_role_assignments, primary_key: false) do
      add :club_id, :text, null: false
      add :membership_id, :text, null: false
      add :person_id, :text, null: false
      add :role_id, :text, null: false
      add :active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime_usec)
    end

    create index(:membership_role_assignments, [:club_id, :role_id])
    create index(:membership_role_assignments, [:club_id, :person_id])
    create index(:membership_role_assignments, [:membership_id])
    create unique_index(:membership_role_assignments, [:membership_id, :role_id])

    create table(:membership_member_permissions, primary_key: false) do
      add :club_id, :text, null: false
      add :membership_id, :text, null: false
      add :person_id, :text, null: false
      add :permission, :text, null: false
      add :grant_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime_usec)
    end

    create index(:membership_member_permissions, [:club_id, :person_id])
    create index(:membership_member_permissions, [:club_id, :membership_id])
    create index(:membership_member_permissions, [:club_id, :permission])

    create unique_index(:membership_member_permissions, [
             :club_id,
             :person_id,
             :membership_id,
             :permission
           ])
  end
end
