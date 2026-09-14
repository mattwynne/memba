defmodule Memba.Repo.Migrations.AddNormalizedGroupNameUniqueness do
  use Ecto.Migration

  def up do
    alter table(:membership_groups) do
      add :name_uniqueness_key, :text
    end

    flush()

    backfill_name_uniqueness_keys()

    execute("ALTER TABLE membership_groups ALTER COLUMN name_uniqueness_key SET NOT NULL")

    create unique_index(:membership_groups, [:club_id, :name_uniqueness_key],
             name: :membership_groups_club_normalized_name_index
           )
  end

  def down do
    drop index(:membership_groups, [:club_id, :name_uniqueness_key],
           name: :membership_groups_club_normalized_name_index
         )

    alter table(:membership_groups) do
      remove :name_uniqueness_key
    end
  end

  defp backfill_name_uniqueness_keys do
    result = repo().query!("SELECT group_id, name FROM membership_groups", [])

    Enum.each(result.rows, fn [group_id, name] ->
      repo().query!(
        """
        UPDATE membership_groups
        SET name_uniqueness_key = $1
        WHERE group_id = $2
        """,
        [name_uniqueness_key(name), group_id]
      )
    end)
  end

  # Keep this historical migration self-contained while matching
  # Memba.Membership.GroupName.uniqueness_key/1 at the time the key is introduced.
  defp name_uniqueness_key(name) do
    name
    |> String.trim()
    |> String.downcase()
  end
end
