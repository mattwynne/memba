defmodule Memba.Messaging.Commands.AcceptInboundClubEmail do
  @moduledoc """
  Command to record that a provider inbound email was accepted as a club message.

  The inbound email aggregate remains keyed by provider retry identity. The
  caller supplies the created message aggregate identity after posting through
  the normal message-send flow.
  """

  @enforce_keys [
    :inbound_email_id,
    :inbound_email,
    :to_address,
    :club_id,
    :sender_id,
    :message_id
  ]
  defstruct [
    :inbound_email_id,
    :inbound_email,
    :to_address,
    :club_id,
    :sender_id,
    :message_id
  ]
end
