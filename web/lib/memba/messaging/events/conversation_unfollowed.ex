defmodule Memba.Messaging.Events.ConversationUnfollowed do
  @moduledoc """
  Event raised when a member stops following a club-message conversation or a
  membership cleanup cutoff is recorded.

  `follow_retained` is true when an older cleanup records its cutoff while
  preserving a follow established by a newer membership generation. Historic
  events predate the field and are interpreted as removing the follow.

  Cleanup events identify `removed_group_id` so another group may independently
  authorize a same-generation follow. Historic cleanup events without it remain
  conversation-wide cutoffs.
  """

  @derive Jason.Encoder
  @enforce_keys [:follow_id, :club_id, :conversation_id, :member_id]
  defstruct [
    :follow_id,
    :club_id,
    :conversation_id,
    :member_id,
    :cleanup_id,
    :membership_generation,
    :removed_group_id,
    follow_retained: false
  ]
end
