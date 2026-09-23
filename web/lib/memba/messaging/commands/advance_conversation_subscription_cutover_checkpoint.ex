defmodule Memba.Messaging.Commands.AdvanceConversationSubscriptionCutoverCheckpoint do
  @moduledoc "Advance the durable ordered legacy-follow reconciliation checkpoint."

  @enforce_keys [
    :cutover_id,
    :namespace,
    :expected_cursor,
    :person_id,
    :conversation_id,
    :reconciliation_key
  ]
  defstruct @enforce_keys
end
