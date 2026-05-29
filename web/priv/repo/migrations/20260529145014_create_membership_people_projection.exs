defmodule Memba.Repo.Migrations.CreateMembershipPeopleProjection do
  use Ecto.Migration

  def change do
    create table(:membership_people, primary_key: false) do
      add :person_id, :uuid, primary_key: true
      add :name, :text, null: false
      add :email, :text, null: false

      timestamps(type: :utc_datetime_usec)
    end
  end
end
