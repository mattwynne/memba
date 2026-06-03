defmodule Memba.Messaging.Events.InboundClubEmailAccepted do
  @moduledoc """
  Event raised when an inbound provider email has been accepted as a club message.
  """

  @derive Jason.Encoder
  @enforce_keys [
    :inbound_email_id,
    :provider,
    :provider_message_id,
    :from_address,
    :to_address,
    :club_id,
    :sender_id,
    :message_id
  ]
  defstruct [
    :inbound_email_id,
    :provider,
    :provider_message_id,
    :provider_event_id,
    :from_address,
    :to_address,
    :club_id,
    :sender_id,
    :message_id
  ]
end
