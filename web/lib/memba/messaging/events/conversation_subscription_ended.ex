defmodule Memba.Messaging.Events.ConversationSubscriptionEnded do
  @moduledoc "Final fact and tombstone for one explicit conversation unfollow."
  @derive Jason.Encoder
  @enforce_keys [:person_id, :conversation_id, :subscription_id, :unfollow_id]
  defstruct @enforce_keys
end
