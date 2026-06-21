defmodule Memba.Messaging.EmailDeliveryStatus do
  @moduledoc """
  Shared status vocabulary for provider dispatch-backed email deliveries.

  These values are persisted on `messaging_email_deliveries` and mirrored by the
  database check constraint. Keep this module and that constraint in sync when
  the delivery lifecycle or webhook outcome vocabulary changes.
  """

  @pending "pending"
  @dispatching "dispatching"
  @sent "sent"
  @failed "failed"

  @delivered "delivered"
  @delayed "delayed"
  @bounced "bounced"
  @spam_complaint "spam_complaint"

  @dispatch_lifecycle_statuses [@pending, @dispatching, @sent, @failed]
  @provider_webhook_statuses [@delivered, @delayed, @bounced, @spam_complaint]
  @valid_statuses @dispatch_lifecycle_statuses ++ @provider_webhook_statuses

  def pending, do: @pending
  def dispatching, do: @dispatching
  def sent, do: @sent
  def failed, do: @failed

  def delivered, do: @delivered
  def delayed, do: @delayed
  def bounced, do: @bounced
  def spam_complaint, do: @spam_complaint

  def dispatch_lifecycle_statuses, do: @dispatch_lifecycle_statuses
  def provider_webhook_statuses, do: @provider_webhook_statuses
  def valid_statuses, do: @valid_statuses

  def valid?(status) when is_binary(status), do: status in @valid_statuses
  def valid?(_status), do: false
end
