defmodule Memba.Messaging.Events.ConversationSubscriptionAuthorizationGranted do
  @moduledoc "Fact granting a subscription through exact custom or system authority."
  @derive Jason.Encoder
  @enforce_keys [
    :person_id,
    :conversation_id,
    :subscription_id,
    :subscription_intent_id,
    :authority_decision_id,
    :authorization_id,
    :club_id,
    :club_membership_id,
    :club_stream_version,
    :group_membership_id,
    :authority_kind
  ]
  defstruct @enforce_keys
end
