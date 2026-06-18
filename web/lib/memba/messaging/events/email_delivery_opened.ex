defmodule Memba.Messaging.Events.EmailDeliveryOpened do
  @moduledoc """
  Deserialization tombstone for historic email-open events.

  Deprecated replay shim only: Memba no longer tracks opened email deliveries.
  Keep this event struct so historic event-store records can deserialize during
  aggregate replay and projection rebuilds. Do not emit, extend, or add new
  behaviour around this event.
  """

  @derive Jason.Encoder
  @enforce_keys [:message_id, :delivery_id]
  defstruct [:message_id, :delivery_id]
end
