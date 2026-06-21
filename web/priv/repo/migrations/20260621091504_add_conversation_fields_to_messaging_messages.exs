defmodule Memba.Repo.Migrations.AddConversationFieldsToMessagingMessages do
  use Ecto.Migration

  def up do
    alter table(:messaging_messages) do
      add :conversation_id, :text
      add :reply_to_message_id, :text
    end

    execute("""
    UPDATE messaging_messages
    SET conversation_id = message_id
    WHERE conversation_id IS NULL
    """)

    alter table(:messaging_messages) do
      modify :conversation_id, :text, null: false
    end

    create index(:messaging_messages, [:conversation_id])
  end

  def down do
    drop_if_exists index(:messaging_messages, [:conversation_id])

    alter table(:messaging_messages) do
      remove :reply_to_message_id
      remove :conversation_id
    end
  end
end
