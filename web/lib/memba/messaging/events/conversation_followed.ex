defmodule Memba.Messaging.Events.ConversationFollowed do
  @moduledoc """
  Event raised when a member follows a club-message conversation.

  `authorizing_group_ids` records the active conversation groups that made the
  follow valid at its action boundary. Historic events without the field use
  conversation-wide generation ordering.
  """

  @derive Jason.Encoder
  @enforce_keys [:follow_id, :club_id, :conversation_id, :member_id]
  defstruct [
    :follow_id,
    :club_id,
    :conversation_id,
    :member_id,
    :membership_generation,
    authorizing_group_ids: []
  ]
end
