defmodule Memba.Messaging.Events.ConversationSubscriptionIntentStarted do
  @moduledoc "Fact binding a subscription intent immutably to a canonical authority decision."
  @derive Jason.Encoder
  @enforce_keys [
    :person_id,
    :club_id,
    :conversation_id,
    :conversation_group_ids,
    :conversation_stream_version,
    :subscription_id,
    :subscription_intent_id,
    :authority_decision_id,
    :source,
    :club_membership_id,
    :group_membership_ids
  ]
  defstruct @enforce_keys
end
