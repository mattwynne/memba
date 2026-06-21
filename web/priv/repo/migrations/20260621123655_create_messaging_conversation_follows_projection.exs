defmodule Memba.Repo.Migrations.CreateMessagingConversationFollowsProjection do
  use Ecto.Migration

  def change do
    create table(:messaging_conversation_follows, primary_key: false) do
      add :follow_id, :string, primary_key: true
      add :club_id, :string, null: false
      add :conversation_id, :string, null: false
      add :member_id, :string, null: false
      add :following, :boolean, null: false, default: true

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:messaging_conversation_follows, [:conversation_id, :member_id])
    create index(:messaging_conversation_follows, [:conversation_id, :following])
    create index(:messaging_conversation_follows, [:club_id, :conversation_id, :following])
  end
end
