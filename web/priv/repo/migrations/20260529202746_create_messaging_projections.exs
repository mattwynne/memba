defmodule Memba.Repo.Migrations.CreateMessagingProjections do
  use Ecto.Migration

  def change do
    create table(:messaging_messages, primary_key: false) do
      add :message_id, :uuid, primary_key: true
      add :club_id, :uuid, null: false
      add :sender_id, :uuid, null: false
      add :subject, :text, null: false
      add :body, :text, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:messaging_messages, [:club_id])
    create index(:messaging_messages, [:sender_id])

    create table(:messaging_email_deliveries, primary_key: false) do
      add :delivery_id, :uuid, primary_key: true
      add :message_id, :uuid, null: false
      add :recipient_id, :uuid, null: false
      add :recipient_name, :text, null: false
      add :recipient_address, :text, null: false
      add :channel, :text, null: false
      add :status, :text, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:messaging_email_deliveries, [:message_id])
    create index(:messaging_email_deliveries, [:recipient_id])
    create unique_index(:messaging_email_deliveries, [:message_id, :recipient_id])
  end
end
