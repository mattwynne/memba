defmodule Memba.Messaging.Events.InboundEmailReceived do
  @moduledoc """
  Event raised when a provider inbound email is first seen by Messaging.

  Later inbound-email events record the accepted/rejected business outcome. This
  event gives the inbound-email aggregate an event-sourced identity and makes
  provider retry handling command-side rather than projection-invented.
  """

  @derive Jason.Encoder
  @enforce_keys [:inbound_email_id, :provider, :provider_message_id]
  defstruct [:inbound_email_id, :provider, :provider_message_id, :provider_event_id]
end
