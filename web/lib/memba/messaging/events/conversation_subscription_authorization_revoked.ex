defmodule Memba.Messaging.Events.ConversationSubscriptionAuthorizationRevoked do
  @moduledoc "Fact ending one exact conversation-subscription authorization grant."
  @derive Jason.Encoder
  @enforce_keys [
    :person_id,
    :conversation_id,
    :subscription_id,
    :authorization_id,
    :group_membership_id,
    :reason
  ]
  defstruct [
    :person_id,
    :conversation_id,
    :subscription_id,
    :authorization_id,
    :group_membership_id,
    :revocation_id,
    :unfollow_id,
    :reason
  ]
end
