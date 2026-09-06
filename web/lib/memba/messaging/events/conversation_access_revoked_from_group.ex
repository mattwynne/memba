defmodule Memba.Messaging.Events.ConversationAccessRevokedFromGroup do
  @moduledoc """
  Event raised when a conversation revokes a group's existing access.
  """

  @derive Jason.Encoder
  @enforce_keys [:conversation_id, :club_id, :group_id, :access_level]
  defstruct [:conversation_id, :club_id, :group_id, :access_level]
end
