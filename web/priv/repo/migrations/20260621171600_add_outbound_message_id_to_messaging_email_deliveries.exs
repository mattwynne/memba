defmodule Memba.Repo.Migrations.AddOutboundMessageIdToMessagingEmailDeliveries do
  use Ecto.Migration

  def up do
    alter table(:messaging_email_deliveries) do
      add :outbound_message_id, :text
    end

    execute("""
    UPDATE messaging_email_deliveries
    SET outbound_message_id = '<memba.' || delivery_id || '.' || message_id || '@messages.memba.io>'
    WHERE outbound_message_id IS NULL
    """)

    alter table(:messaging_email_deliveries) do
      modify :outbound_message_id, :text, null: false
    end

    create unique_index(:messaging_email_deliveries, [:outbound_message_id])
  end

  def down do
    drop_if_exists unique_index(:messaging_email_deliveries, [:outbound_message_id])

    alter table(:messaging_email_deliveries) do
      remove :outbound_message_id
    end
  end
end
