defmodule Memba.Repo.Migrations.CreateMessagingConversationGroupAccessProjection do
  use Ecto.Migration

  def change do
    create table(:messaging_conversation_group_access, primary_key: false) do
      add :conversation_id, :text, null: false
      add :club_id, :text, null: false
      add :group_id, :text, null: false
      add :access_level, :text, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create constraint(
             :messaging_conversation_group_access,
             :messaging_conversation_group_access_level_check,
             check: "access_level IN ('read', 'write')"
           )

    create unique_index(:messaging_conversation_group_access, [:conversation_id, :group_id],
             name: :messaging_conversation_group_access_unique_index
           )

    create index(:messaging_conversation_group_access, [:club_id, :conversation_id],
             name: :messaging_conversation_group_access_club_index
           )

    create index(:messaging_conversation_group_access, [:group_id],
             name: :messaging_conversation_group_access_group_index
           )
  end
end
