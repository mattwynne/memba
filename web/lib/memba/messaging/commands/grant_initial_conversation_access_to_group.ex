defmodule Memba.Messaging.Commands.GrantInitialConversationAccessToGroup do
  @moduledoc """
  Command to grant a legacy root conversation its first group audience.

  The Message aggregate emits a grant only when the conversation has no existing
  group access. This aggregate-level precondition keeps the backfill safe when
  its projection scan races a newly created conversation's access projection.
  """

  @enforce_keys [:conversation_id, :club_id, :group_id, :access_level]
  defstruct [:conversation_id, :club_id, :group_id, :access_level]
end
