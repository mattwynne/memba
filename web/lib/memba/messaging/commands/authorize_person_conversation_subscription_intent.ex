defmodule Memba.Messaging.Commands.AuthorizePersonConversationSubscriptionIntent do
  @moduledoc """
  Grants an intent only from its originally bound authority decision.

  `current_group_membership_ids` is the result of validating the exact bound
  identities through Membership's canonical decision contract. The aggregate
  will neither accept nor substitute identities absent from the bound decision.
  """

  @enforce_keys [
    :person_id,
    :subscription_intent_id,
    :authority_decision_id,
    :current_group_membership_ids,
    :current_system_authority_kinds,
    :authority_decision
  ]
  defstruct @enforce_keys
end
