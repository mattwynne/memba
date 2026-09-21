defmodule Memba.Messaging.Events.ConversationUnfollowed do
  @moduledoc """
  Event raised when a member stops following a club-message conversation or a
  membership cleanup cutoff is recorded.

  `follow_retained` is true when an older cleanup records its cutoff while
  preserving a follow established by a newer membership generation. Historic
  events predate the field and are interpreted as removing the follow.
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
    follow_retained: false
  ]
end
