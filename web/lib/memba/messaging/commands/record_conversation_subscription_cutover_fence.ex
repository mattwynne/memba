defmodule Memba.Messaging.Commands.RecordConversationSubscriptionCutoverFence do
  @moduledoc "Record the immutable global position used by legacy-follow cutover."

  @enforce_keys [
    :cutover_id,
    :namespace,
    :event_store_schema,
    :event_store_position,
    :writers_stopped_acknowledgement
  ]
  defstruct @enforce_keys
end
