defmodule Memba.Repo.Migrations.AddEmailHandoffRecovery do
  use Ecto.Migration

  def change do
    create table(:messaging_email_handoff_attempts) do
      add :delivery_id,
          references(:messaging_email_deliveries, column: :delivery_id, type: :string),
          null: false

      add :provider, :string, null: false
      add :request, :binary, null: false
      add :state, :string, null: false
      add :detail, :text
      add :started_at, :utc_datetime_usec, null: false
      add :resolved_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create index(:messaging_email_handoff_attempts, [:delivery_id, :id])

    create unique_index(:messaging_email_handoff_attempts, [:delivery_id],
             where: "state = 'in_flight'",
             name: :one_in_flight_email_handoff_per_delivery
           )

    alter table(:messaging_email_deliveries) do
      add :active_attempt_id, :bigint
      add :claim_version, :integer, null: false, default: 0
    end

    execute "ALTER TABLE messaging_email_deliveries DROP CONSTRAINT messaging_email_deliveries_status_check",
            "ALTER TABLE messaging_email_deliveries ADD CONSTRAINT messaging_email_deliveries_status_check CHECK (status IN ('pending', 'dispatching', 'sent', 'failed', 'delivered', 'delayed', 'bounced', 'spam_complaint'))"

    execute "ALTER TABLE messaging_email_deliveries ADD CONSTRAINT messaging_email_deliveries_status_check CHECK (status IN ('pending', 'dispatching', 'uncertain', 'sent', 'failed', 'delivered', 'delayed', 'bounced', 'spam_complaint'))",
            "ALTER TABLE messaging_email_deliveries DROP CONSTRAINT messaging_email_deliveries_status_check"
  end
end
