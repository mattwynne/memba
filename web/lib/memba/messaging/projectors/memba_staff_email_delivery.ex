defmodule Memba.Messaging.Projectors.MembaStaffEmailDelivery do
  @moduledoc """
  Projects email delivery events into the Memba staff email delivery view.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Messaging.App,
    repo: Memba.Repo,
    name: "Memba.Messaging.Projectors.MembaStaffEmailDelivery",
    consistency: :strong

  alias Ecto.Changeset
  alias Memba.Messaging.Events.EmailDeliveryBounced
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Events.EmailDeliveryDelayed
  alias Memba.Messaging.Events.EmailDeliveryDelivered
  alias Memba.Messaging.Events.EmailDeliveryOpened
  alias Memba.Messaging.Events.EmailDeliverySpamComplaint
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery, as: MembaStaffEmailDeliveryProjection
  alias Memba.Repo

  project(%EmailDeliveryCreated{} = event, fn multi ->
    Ecto.Multi.insert(
      multi,
      :messaging_memba_staff_email_delivery,
      %MembaStaffEmailDeliveryProjection{
        delivery_id: event.delivery_id,
        message_id: event.message_id,
        recipient_id: event.recipient_id,
        recipient_name: event.recipient_name,
        recipient_address: event.recipient_email,
        channel: "email",
        status: "sent",
        reason: nil
      }
    )
  end)

  project(%EmailDeliveryDelivered{} = event, fn multi ->
    update_deliverability(multi, event.delivery_id, status: "delivered", reason: nil)
  end)

  project(%EmailDeliveryDelayed{} = event, fn multi ->
    update_deliverability(multi, event.delivery_id, status: "delayed", reason: event.reason)
  end)

  project(%EmailDeliveryBounced{} = event, fn multi ->
    update_deliverability(multi, event.delivery_id, status: "bounced", reason: event.reason)
  end)

  project(%EmailDeliverySpamComplaint{} = event, fn multi ->
    update_deliverability(multi, event.delivery_id,
      status: "spam complaint",
      reason: event.reason
    )
  end)

  project(%EmailDeliveryOpened{} = event, fn multi ->
    update_deliverability(multi, event.delivery_id, status: "opened", reason: nil)
  end)

  defp update_deliverability(multi, delivery_id, attrs) do
    case Repo.get(MembaStaffEmailDeliveryProjection, delivery_id) do
      nil ->
        multi

      deliverability ->
        Ecto.Multi.update(
          multi,
          {:messaging_memba_staff_email_delivery, delivery_id},
          Changeset.change(deliverability, attrs)
        )
    end
  end
end
