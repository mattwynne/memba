defmodule Memba.Messaging.Projectors.InboundEmailSource do
  @moduledoc """
  Projects inbound club email outcome events into source/status records.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Messaging.App,
    repo: Memba.Repo,
    name: "Memba.Messaging.Projectors.InboundEmailSource",
    consistency: :strong

  alias Memba.Messaging.Events.InboundClubEmailAccepted
  alias Memba.Messaging.Events.InboundClubEmailRejected
  alias Memba.Messaging.Projections.InboundEmailSource, as: InboundEmailSourceProjection

  project(%InboundClubEmailAccepted{} = event, fn multi ->
    Ecto.Multi.insert(multi, :messaging_inbound_email_source, %InboundEmailSourceProjection{
      inbound_email_id: event.inbound_email_id,
      provider: event.provider,
      provider_message_id: event.provider_message_id,
      provider_event_id: event.provider_event_id,
      from_address: event.from_address,
      to_address: event.to_address,
      status: "accepted",
      club_id: event.club_id,
      sender_id: event.sender_id,
      message_id: event.message_id
    })
  end)

  project(%InboundClubEmailRejected{} = event, fn multi ->
    Ecto.Multi.insert(multi, :messaging_inbound_email_source, %InboundEmailSourceProjection{
      inbound_email_id: event.inbound_email_id,
      provider: event.provider,
      provider_message_id: event.provider_message_id,
      provider_event_id: event.provider_event_id,
      from_address: event.from_address,
      to_address: event.to_address,
      status: "rejected",
      rejection_reason: event.rejection_reason,
      rejection_email_delivery_reference: event.rejection_email_delivery_reference
    })
  end)
end
