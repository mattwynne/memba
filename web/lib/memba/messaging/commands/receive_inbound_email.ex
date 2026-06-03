defmodule Memba.Messaging.Commands.ReceiveInboundEmail do
  @moduledoc """
  Command wrapper for a provider-neutral inbound club-message email.

  Routing, idempotency, destination resolution, authorization, and posting rules
  are implemented in later inbound-email tasks. This command establishes the
  Messaging-facing input shape without coupling the domain API to Resend or any
  other provider payload.
  """

  @enforce_keys [:inbound_email_id, :inbound_email]
  defstruct [:inbound_email_id, :inbound_email]
end
