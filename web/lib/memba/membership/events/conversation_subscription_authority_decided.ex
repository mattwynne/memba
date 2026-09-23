defmodule Memba.Membership.Events.ConversationSubscriptionAuthorityDecided do
  @moduledoc "Canonical Club-stream fact binding a conversation authority decision."

  @derive Jason.Encoder
  @enforce_keys [
    :club_id,
    :person_id,
    :subscription_intent_id,
    :source,
    :conversation_id,
    :conversation_group_ids,
    :conversation_stream_version,
    :authority_request_id,
    :authority_decision_id,
    :club_membership_id,
    :group_membership_ids,
    :system_authority_kinds,
    :club_stream_version
  ]
  defstruct @enforce_keys ++
              [
                :reconciliation_fence_id,
                :reconciliation_fence_position,
                :reconciliation_event_store_schema
              ]
end
