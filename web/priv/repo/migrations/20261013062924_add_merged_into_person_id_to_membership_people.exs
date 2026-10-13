defmodule Memba.Repo.Migrations.AddMergedIntoPersonIdToMembershipPeople do
  use Ecto.Migration

  def change do
    alter table(:membership_people) do
      add :merged_into_person_id,
          references(:membership_people,
            column: :person_id,
            type: :string,
            on_delete: :restrict
          )
    end

    create index(:membership_people, [:merged_into_person_id])
  end
end
