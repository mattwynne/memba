defmodule Memba.Messaging.Commands.FollowConversation do
  @moduledoc """
  Command to follow a club-message conversation for reply notifications.
  """

  @enforce_keys [:club_id, :conversation_id, :member_id]
  defstruct [:club_id, :conversation_id, :member_id]
end
