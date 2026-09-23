defmodule Memba.Membership.Commands.DecideConversationSubscriptionAuthority do
  @moduledoc """
  Internal Club command recording one server-issued conversation authority decision.
  """

  @enforce_keys [
    :conversation_authority_descriptor,
    :club_id,
    :person_id,
    :subscription_intent_id,
    :source,
    :conversation_id,
    :conversation_group_ids,
    :conversation_stream_version,
    :authority_request_id,
    :authority_decision_id
  ]
  defstruct @enforce_keys ++ [:fenced_authority_decision]
end
