defmodule Memba.Messaging.Events.InboundClubEmailRejected do
  @moduledoc """
  Event raised when an inbound provider email is rejected before posting.
  """

  @derive Jason.Encoder
  @enforce_keys [
    :inbound_email_id,
    :provider,
    :provider_message_id,
    :from_address,
    :rejection_reason
  ]
  defstruct [
    :inbound_email_id,
    :provider,
    :provider_message_id,
    :provider_event_id,
    :from_address,
    :to_address,
    :rejection_reason,
    :rejection_email_delivery_reference
  ]
end
