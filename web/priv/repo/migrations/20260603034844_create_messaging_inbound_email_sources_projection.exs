defmodule Memba.Repo.Migrations.CreateMessagingInboundEmailSourcesProjection do
  use Ecto.Migration

  def change do
    create table(:messaging_inbound_email_sources, primary_key: false) do
      add :inbound_email_id, :text, primary_key: true
      add :provider, :text, null: false
      add :provider_message_id, :text, null: false
      add :provider_event_id, :text
      add :from_address, :text, null: false
      add :to_address, :text
      add :status, :text, null: false
      add :club_id, :uuid
      add :sender_id, :uuid
      add :message_id, :uuid
      add :rejection_reason, :text
      add :rejection_email_delivery_reference, :text

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:messaging_inbound_email_sources, [:provider, :provider_message_id],
             name: :messaging_inbound_email_sources_provider_message_id_index
           )

    create index(:messaging_inbound_email_sources, [:status])
    create index(:messaging_inbound_email_sources, [:message_id])
  end
end
