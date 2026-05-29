defmodule Memba.Repo.Migrations.CreateMembershipMembershipsProjection do
  use Ecto.Migration

  def change do
    create table(:membership_memberships, primary_key: false) do
      add :membership_id, :uuid, primary_key: true
      add :club_id, :uuid, null: false
      add :person_id, :uuid, null: false
      add :active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime_usec)
    end

    create index(:membership_memberships, [:club_id])
    create index(:membership_memberships, [:person_id])
  end
end
