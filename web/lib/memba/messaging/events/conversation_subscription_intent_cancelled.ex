defmodule Memba.Messaging.Events.ConversationSubscriptionIntentCancelled do
  @moduledoc "Fact that an exact subscription intent can no longer produce grants."
  @derive Jason.Encoder
  @enforce_keys [
    :person_id,
    :conversation_id,
    :subscription_id,
    :subscription_intent_id,
    :cancellation_id,
    :reason
  ]
  defstruct @enforce_keys
end
