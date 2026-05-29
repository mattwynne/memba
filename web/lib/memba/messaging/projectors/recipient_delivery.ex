defmodule Memba.Messaging.Projectors.RecipientDelivery do
  @moduledoc """
  Projects recipient delivery events into the Messaging delivery read model.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Messaging.App,
    repo: Memba.Repo,
    name: "Memba.Messaging.Projectors.RecipientDelivery",
    consistency: :strong

  alias Memba.Messaging.Events.RecipientDeliveryCreated
  alias Memba.Messaging.Projections.RecipientDelivery, as: RecipientDeliveryProjection

  project(%RecipientDeliveryCreated{} = event, fn multi ->
    Ecto.Multi.insert(multi, :messaging_recipient_delivery, %RecipientDeliveryProjection{
      delivery_id: event.delivery_id,
      message_id: event.message_id,
      recipient_id: event.recipient_id,
      recipient_name: event.recipient_name,
      recipient_address: event.recipient_email,
      channel: "email",
      status: "sent"
    })
  end)
end
