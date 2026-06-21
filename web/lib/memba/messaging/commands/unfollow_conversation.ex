defmodule Memba.Messaging.Commands.UnfollowConversation do
  @moduledoc """
  Command to stop following a club-message conversation.
  """

  @enforce_keys [:club_id, :conversation_id, :member_id]
  defstruct [:club_id, :conversation_id, :member_id]
end
