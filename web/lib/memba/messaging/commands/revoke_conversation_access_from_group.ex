defmodule Memba.Messaging.Commands.RevokeConversationAccessFromGroup do
  @moduledoc """
  Command to revoke a club-scoped group's access to an existing root conversation.

  The conversation identity is the root message identity. Replaying the root
  stream lets the Message aggregate make repeated revocations idempotent.
  """

  @enforce_keys [:conversation_id, :club_id, :group_id]
  defstruct [:conversation_id, :club_id, :group_id]
end
