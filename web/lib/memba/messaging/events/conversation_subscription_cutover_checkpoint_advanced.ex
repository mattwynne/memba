defmodule Memba.Messaging.Events.ConversationSubscriptionCutoverCheckpointAdvanced do
  @moduledoc "A durable terminal-item checkpoint in legacy-follow key order."

  @derive Jason.Encoder
  @enforce_keys [
    :cutover_id,
    :namespace,
    :previous_cursor,
    :person_id,
    :conversation_id,
    :reconciliation_key
  ]
  defstruct @enforce_keys
end
