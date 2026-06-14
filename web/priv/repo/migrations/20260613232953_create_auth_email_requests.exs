defmodule Memba.Repo.Migrations.CreateAuthEmailRequests do
  use Ecto.Migration

  def change do
    create table(:auth_email_requests, primary_key: false) do
      add :request_id, :text, primary_key: true
      add :recipient_email, :text
      add :status, :text, null: false, default: "created"

      add :provider, :text
      add :provider_message_id, :text
      add :provider_message_stream, :text
      add :provider_event_id, :text
      add :provider_event_type, :text
      add :provider_reason, :text

      add :sent_at, :utc_datetime_usec
      add :provider_reported_at, :utc_datetime_usec
      add :expires_at, :utc_datetime_usec, null: false
      add :retain_until, :utc_datetime_usec, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:auth_email_requests, [:status, :inserted_at])

    create index(:auth_email_requests, [:provider_message_id],
             where: "provider_message_id IS NOT NULL"
           )

    create index(:auth_email_requests, [:provider_event_id],
             where: "provider_event_id IS NOT NULL"
           )

    create index(:auth_email_requests, [:expires_at])
    create index(:auth_email_requests, [:retain_until])

    create constraint(:auth_email_requests, :auth_email_requests_status_check,
             check:
               "status IN ('created', 'sent', 'provider_accepted', 'provider_delayed', 'provider_failed')"
           )

    create constraint(:auth_email_requests, :auth_email_requests_retain_after_expiry_check,
             check: "retain_until > expires_at"
           )
  end
end
