defmodule Memba.Repo.Migrations.CreateMessagingMemberReceiptsProjection do
  use Ecto.Migration

  def change do
    create table(:messaging_member_email_deliveries, primary_key: false) do
      add :delivery_id, :uuid, primary_key: true
      add :message_id, :uuid, null: false
      add :recipient_id, :uuid, null: false
      add :recipient_name, :text, null: false
      add :status, :text, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:messaging_member_email_deliveries, [:message_id])
    create index(:messaging_member_email_deliveries, [:recipient_id])
    create unique_index(:messaging_member_email_deliveries, [:message_id, :recipient_id])
  end
end
