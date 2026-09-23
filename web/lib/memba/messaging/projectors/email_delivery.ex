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
  alias Memba.Messaging.EmailDeliveryStatus
  alias Memba.Messaging.OutboundMessageID
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection

  project(%EmailDeliveryCreated{} = event, fn multi ->
    Ecto.Multi.insert(multi, :messaging_email_delivery, %EmailDeliveryProjection{
      delivery_id: event.delivery_id,
      message_id: event.message_id,
      outbound_message_id: OutboundMessageID.for_delivery(event.delivery_id, event.message_id),
      recipient_id: event.recipient_id,
      recipient_name: event.recipient_name,
      recipient_address: event.recipient_email,
      subscription_authorization_id: event.subscription_authorization_id,
      authority_decision_id: event.authority_decision_id,
      authority_kind: event.authority_kind,
      authority_club_id: event.authority_club_id,
      authority_club_membership_id: event.authority_club_membership_id,
      authority_group_membership_id: event.authority_group_membership_id,
      authority_club_stream_version: event.authority_club_stream_version,
      channel: "email",
      status: EmailDeliveryStatus.pending(),
      attempt_count: 0
    })
  end)

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    Memba.ReadModelChanges.publish(__MODULE__, event, metadata, changes)
  end
end
