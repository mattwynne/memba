defmodule Memba.Repo.Migrations.CreateMembershipClubsProjection do
  use Ecto.Migration

  def change do
    create table(:membership_clubs, primary_key: false) do
      add :club_id, :uuid, primary_key: true
      add :name, :text, null: false

      timestamps(type: :utc_datetime_usec)
    end
  end
end
