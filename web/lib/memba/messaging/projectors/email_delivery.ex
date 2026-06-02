defmodule Memba.Messaging.Projectors.EmailDelivery do
  @moduledoc """
  Projects email delivery events into the Messaging delivery read model.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Messaging.App,
    repo: Memba.Repo,
    name: "Memba.Messaging.Projectors.EmailDelivery",
    consistency: :strong

  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection

  project(%EmailDeliveryCreated{} = event, fn multi ->
    Ecto.Multi.insert(multi, :messaging_email_delivery, %EmailDeliveryProjection{
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
