defmodule Memba.Repo.Migrations.CreateMembershipMembershipsProjection do
  use Ecto.Migration

  def change do
    create table(:membership_memberships, primary_key: false) do
      add :membership_id, :text, primary_key: true
      add :club_id, :text, null: false
      add :person_id, :text, null: false
      add :active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime_usec)
    end

    create index(:membership_memberships, [:club_id])
    create index(:membership_memberships, [:person_id])
  end
end
