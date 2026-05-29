defmodule Memba.Messaging.Projectors.MemberReceipt do
  @moduledoc """
  Projects recipient delivery events into member-facing receipt statuses.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Messaging.App,
    repo: Memba.Repo,
    name: "Memba.Messaging.Projectors.MemberReceipt",
    consistency: :strong

  alias Ecto.Changeset
  alias Memba.Messaging.Events.RecipientDeliveryBounced
  alias Memba.Messaging.Events.RecipientDeliveryCreated
  alias Memba.Messaging.Events.RecipientDeliveryDelayed
  alias Memba.Messaging.Events.RecipientDeliveryDelivered
  alias Memba.Messaging.Events.RecipientDeliveryOpened
  alias Memba.Messaging.Events.RecipientDeliverySpamComplaint
  alias Memba.Messaging.Projections.MemberReceipt, as: MemberReceiptProjection
  alias Memba.Repo

  project(%RecipientDeliveryCreated{} = event, fn multi ->
    Ecto.Multi.insert(multi, :messaging_member_receipt, %MemberReceiptProjection{
      delivery_id: event.delivery_id,
      message_id: event.message_id,
      recipient_id: event.recipient_id,
      recipient_name: event.recipient_name,
      receipt_status: "sent"
    })
  end)

  project(%RecipientDeliveryDelivered{} = event, fn multi ->
    update_receipt_status(multi, event.delivery_id, "delivered")
  end)

  project(%RecipientDeliveryDelayed{} = event, fn multi ->
    update_receipt_status(multi, event.delivery_id, "delivery problem")
  end)

  project(%RecipientDeliveryBounced{} = event, fn multi ->
    update_receipt_status(multi, event.delivery_id, "delivery problem")
  end)

  project(%RecipientDeliverySpamComplaint{} = event, fn multi ->
    update_receipt_status(multi, event.delivery_id, "delivery problem")
  end)

  project(%RecipientDeliveryOpened{} = event, fn multi ->
    update_receipt_status(multi, event.delivery_id, "opened")
  end)

  defp update_receipt_status(multi, delivery_id, receipt_status) do
    case Repo.get(MemberReceiptProjection, delivery_id) do
      nil ->
        multi

      receipt ->
        Ecto.Multi.update(
          multi,
          {:messaging_member_receipt, delivery_id},
          Changeset.change(receipt, receipt_status: receipt_status)
        )
    end
  end
end
