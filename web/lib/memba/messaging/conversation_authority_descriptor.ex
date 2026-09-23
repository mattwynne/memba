defmodule Memba.Messaging.ConversationAuthorityDescriptor do
  @moduledoc """
  Integrity-bound description of a canonical Messaging conversation audience.

  Messaging issues this opaque value from the root Message aggregate/history.
  Membership accepts no caller-selected club or audience identifiers.
  """

  @opaque t :: %__MODULE__{}

  @enforce_keys [
    :club_id,
    :person_id,
    :subscription_intent_id,
    :source,
    :conversation_id,
    :conversation_group_ids,
    :conversation_stream_version,
    :signature
  ]
  defstruct @enforce_keys ++
              [
                :reconciliation_fence_id,
                :reconciliation_fence_position,
                :reconciliation_event_store_schema
              ]
end
