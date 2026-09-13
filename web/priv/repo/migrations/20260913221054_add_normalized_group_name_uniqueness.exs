defmodule Memba.Repo.Migrations.AddNormalizedGroupNameUniqueness do
  use Ecto.Migration

  def up do
    create unique_index(:membership_groups, [:club_id, "(lower(btrim(name)))"],
             name: :membership_groups_club_normalized_name_index
           )
  end

  def down do
    drop_if_exists index(:membership_groups, [:club_id, "(lower(btrim(name)))"],
                     name: :membership_groups_club_normalized_name_index
                   )
  end
end
