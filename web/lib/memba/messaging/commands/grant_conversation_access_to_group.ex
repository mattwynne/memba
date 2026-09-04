defmodule Memba.Messaging.Commands.GrantConversationAccessToGroup do
  @moduledoc """
  Command to grant a club-scoped group access to an existing root conversation.

  The conversation identity is the root message identity. Replaying the root
  message stream lets the Message aggregate decide idempotently whether a new
  `ConversationAccessGrantedToGroup` event is needed.
  """

  @enforce_keys [:conversation_id, :club_id, :group_id, :access_level]
  defstruct [:conversation_id, :club_id, :group_id, :access_level]
end
