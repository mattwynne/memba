defmodule Memba.Messaging.Commands.RejectInboundClubEmail do
  @moduledoc """
  Command to record that a provider inbound email was rejected before posting.

  Rejection email delivery is added separately; this command records the
  event-sourced business outcome for idempotency and audit projections.
  """

  @enforce_keys [
    :inbound_email_id,
    :inbound_email,
    :rejection_reason
  ]
  defstruct [
    :inbound_email_id,
    :inbound_email,
    :to_address,
    :rejection_reason,
    :rejection_email_delivery_reference
  ]
end
