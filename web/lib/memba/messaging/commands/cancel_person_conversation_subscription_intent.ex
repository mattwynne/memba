defmodule Memba.Messaging.Commands.CancelPersonConversationSubscriptionIntent do
  @moduledoc "Cancels one exact, previously started subscription intent."

  @enforce_keys [:person_id, :subscription_intent_id, :cancellation_id, :reason]
  defstruct @enforce_keys
end
