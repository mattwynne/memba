defmodule Memba.Messaging.Events.LegacyConversationFollowReconciled do
  @moduledoc "Terminal marker for one fenced legacy-follow reconciliation decision."

  @derive Jason.Encoder
  @enforce_keys [
    :person_id,
    :conversation_id,
    :subscription_id,
    :reconciliation_key,
    :subscription_intent_id,
    :authority_decision_id,
    :fence_position,
    :club_id,
    :conversation_group_ids,
    :club_membership_id,
    :club_stream_version,
    :outcome,
    :group_membership_ids,
    :system_authority_kinds
  ]
  defstruct @enforce_keys
end
