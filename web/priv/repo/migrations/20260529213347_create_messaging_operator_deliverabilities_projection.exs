defmodule Memba.Repo.Migrations.CreateMessagingOperatorDeliverabilitiesProjection do
  use Ecto.Migration

  def change do
    create table(:messaging_memba_staff_email_deliveries, primary_key: false) do
      add :delivery_id, :uuid, primary_key: true
      add :message_id, :uuid, null: false
      add :recipient_id, :uuid, null: false
      add :recipient_name, :text, null: false
      add :recipient_address, :text, null: false
      add :channel, :text, null: false
      add :status, :text, null: false
      add :reason, :text

      timestamps(type: :utc_datetime_usec)
    end

    create index(:messaging_memba_staff_email_deliveries, [:message_id])
    create index(:messaging_memba_staff_email_deliveries, [:recipient_id])
    create unique_index(:messaging_memba_staff_email_deliveries, [:message_id, :recipient_id])
  end
end
