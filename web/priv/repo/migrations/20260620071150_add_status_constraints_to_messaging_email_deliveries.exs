defmodule Memba.Repo.Migrations.AddStatusConstraintsToMessagingEmailDeliveries do
  use Ecto.Migration

  def change do
    create constraint(:messaging_email_deliveries, :messaging_email_deliveries_status_check,
             check:
               "status IN ('pending', 'dispatching', 'sent', 'failed', 'delivered', 'delayed', 'bounced', 'spam_complaint')"
           )
  end
end
