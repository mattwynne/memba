defmodule Memba.Repo.Migrations.AddEmailSlugToMembershipGroups do
  use Ecto.Migration

  def change do
    alter table(:membership_groups) do
      add :email_slug, :text
    end

    create unique_index(:membership_groups, [:club_id, :email_slug],
             where: "email_slug IS NOT NULL"
           )
  end
end
