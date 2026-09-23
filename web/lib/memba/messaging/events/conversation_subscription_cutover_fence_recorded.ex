defmodule Memba.Messaging.Events.ConversationSubscriptionCutoverFenceRecorded do
  @moduledoc "The durable global event-store fence for legacy-follow cutover."

  @derive Jason.Encoder
  @enforce_keys [
    :cutover_id,
    :namespace,
    :event_store_schema,
    :event_store_position,
    :writers_stopped_acknowledgement
  ]
  defstruct @enforce_keys
end
