defmodule Memba.Messaging.Commands.StartPersonConversationSubscriptionIntent do
  @moduledoc """
  Starts a server-authorized subscription intent in the owning person's stream.

  The authority decision and its complete group-membership result are immutable
  inputs obtained by Messaging, never product-supplied authorization claims.
  """

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
    :group_membership_ids,
    :authority_decision
  ]
  defstruct @enforce_keys
end
