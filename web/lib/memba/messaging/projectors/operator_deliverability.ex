defmodule Memba.Messaging.Projectors.OperatorDeliverability do
  @moduledoc """
  Projects recipient delivery events into the operator deliverability view.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Messaging.App,
    repo: Memba.Repo,
    name: "Memba.Messaging.Projectors.OperatorDeliverability",
    consistency: :strong

  alias Ecto.Changeset
  alias Memba.Messaging.Events.RecipientDeliveryBounced
  alias Memba.Messaging.Events.RecipientDeliveryCreated
  alias Memba.Messaging.Events.RecipientDeliveryDelayed
  alias Memba.Messaging.Events.RecipientDeliveryDelivered
  alias Memba.Messaging.Events.RecipientDeliveryOpened
  alias Memba.Messaging.Events.RecipientDeliverySpamComplaint
  alias Memba.Messaging.Projections.OperatorDeliverability, as: OperatorDeliverabilityProjection
  alias Memba.Repo

  project(%RecipientDeliveryCreated{} = event, fn multi ->
    Ecto.Multi.insert(
      multi,
      :messaging_operator_deliverability,
      %OperatorDeliverabilityProjection{
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

  project(%RecipientDeliveryDelivered{} = event, fn multi ->
    update_deliverability(multi, event.delivery_id, status: "delivered", reason: nil)
  end)

  project(%RecipientDeliveryDelayed{} = event, fn multi ->
    update_deliverability(multi, event.delivery_id, status: "delayed", reason: event.reason)
  end)

  project(%RecipientDeliveryBounced{} = event, fn multi ->
    update_deliverability(multi, event.delivery_id, status: "bounced", reason: event.reason)
  end)

  project(%RecipientDeliverySpamComplaint{} = event, fn multi ->
    update_deliverability(multi, event.delivery_id,
      status: "spam complaint",
      reason: event.reason
    )
  end)

  project(%RecipientDeliveryOpened{} = event, fn multi ->
    update_deliverability(multi, event.delivery_id, status: "opened", reason: nil)
  end)

  defp update_deliverability(multi, delivery_id, attrs) do
    case Repo.get(OperatorDeliverabilityProjection, delivery_id) do
      nil ->
        multi

      deliverability ->
        Ecto.Multi.update(
          multi,
          {:messaging_operator_deliverability, delivery_id},
          Changeset.change(deliverability, attrs)
        )
    end
  end
end
