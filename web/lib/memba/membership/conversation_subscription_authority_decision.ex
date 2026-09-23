defmodule Memba.Membership.ConversationSubscriptionAuthorityDecision do
  @moduledoc """
  Server-issued proof of one canonical Club aggregate authority decision.

  Callers may carry this value between bounded contexts, but cannot mint or
  alter valid provenance because Membership signs every immutable field.
  """

  @derive Jason.Encoder
  @type t :: %__MODULE__{}
  @opaque signed_t :: t()

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
    :club_stream_version,
    :signature
  ]
  defstruct @enforce_keys
end
