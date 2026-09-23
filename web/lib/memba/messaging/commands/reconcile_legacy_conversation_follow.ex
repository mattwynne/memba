defmodule Memba.Messaging.Commands.ReconcileLegacyConversationFollow do
  @moduledoc "Materialize one fenced legacy follow in its owning person stream."

  @enforce_keys [
    :person_id,
    :conversation_id,
    :club_id,
    :subscription_id,
    :reconciliation_key,
    :subscription_intent_id,
    :authority_decision_id,
    :authority_decision,
    :fence_position,
    :conversation_group_ids,
    :club_membership_id,
    :club_stream_version,
    :group_membership_ids,
    :system_authority_kinds
  ]
  defstruct @enforce_keys
end
