defmodule Memba.Messaging.Projectors.MemberEmailDelivery do
  @moduledoc """
  Projects email delivery events into member-facing statuses.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Messaging.App,
    repo: Memba.Repo,
    name: "Memba.Messaging.Projectors.MemberEmailDelivery",
    consistency: :strong

  alias Ecto.Changeset
  alias Memba.Messaging.Events.EmailDeliveryBounced
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Events.EmailDeliveryDelayed
  alias Memba.Messaging.Events.EmailDeliveryDelivered
  alias Memba.Messaging.Events.EmailDeliveryOpened
  alias Memba.Messaging.Events.EmailDeliverySpamComplaint
  alias Memba.Messaging.Projections.MemberEmailDelivery, as: MemberEmailDeliveryProjection
  alias Memba.Repo

  project(%EmailDeliveryCreated{} = event, fn multi ->
    Ecto.Multi.insert(multi, :messaging_member_email_delivery, %MemberEmailDeliveryProjection{
      delivery_id: event.delivery_id,
      message_id: event.message_id,
      recipient_id: event.recipient_id,
      recipient_name: event.recipient_name,
      status: "sent"
    })
  end)

  project(%EmailDeliveryDelivered{} = event, fn multi ->
    update_status(multi, event.delivery_id, "delivered")
  end)

  project(%EmailDeliveryDelayed{} = event, fn multi ->
    update_status(multi, event.delivery_id, "delivery problem")
  end)

  project(%EmailDeliveryBounced{} = event, fn multi ->
    update_status(multi, event.delivery_id, "delivery problem")
  end)

  project(%EmailDeliverySpamComplaint{} = event, fn multi ->
    update_status(multi, event.delivery_id, "delivery problem")
  end)

  project(%EmailDeliveryOpened{} = event, fn multi ->
    update_status(multi, event.delivery_id, "opened")
  end)

  defp update_status(multi, delivery_id, status) do
    case Repo.get(MemberEmailDeliveryProjection, delivery_id) do
      nil ->
        multi

      receipt ->
        Ecto.Multi.update(
          multi,
          {:messaging_member_email_delivery, delivery_id},
          Changeset.change(receipt, status: status)
        )
    end
  end
end
