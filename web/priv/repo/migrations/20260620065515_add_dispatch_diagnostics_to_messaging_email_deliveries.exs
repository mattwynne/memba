defmodule Memba.Repo.Migrations.AddDispatchDiagnosticsToMessagingEmailDeliveries do
  use Ecto.Migration

  def change do
    alter table(:messaging_email_deliveries) do
      add :attempt_count, :integer, null: false, default: 0
      add :latest_error, :text
      add :latest_detail, :text
      add :last_dispatch_attempted_at, :utc_datetime_usec
      add :sent_at, :utc_datetime_usec
      add :failed_at, :utc_datetime_usec
    end
  end
end
