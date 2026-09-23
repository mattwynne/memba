defmodule Memba.Messaging.Events.ConversationSubscriptionAuthorizationGranted do
  @moduledoc "Fact granting a subscription through one exact GroupMembership authority."
  @derive Jason.Encoder
  @enforce_keys [
    :person_id,
    :conversation_id,
    :subscription_id,
    :subscription_intent_id,
    :authority_decision_id,
    :authorization_id,
    :club_membership_id,
    :group_membership_id
  ]
  defstruct @enforce_keys
end
