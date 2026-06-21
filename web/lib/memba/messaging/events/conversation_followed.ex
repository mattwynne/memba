defmodule Memba.Messaging.Events.ConversationFollowed do
  @moduledoc """
  Event raised when a member follows a club-message conversation.
  """

  @derive Jason.Encoder
  @enforce_keys [:follow_id, :club_id, :conversation_id, :member_id]
  defstruct [:follow_id, :club_id, :conversation_id, :member_id]
end
