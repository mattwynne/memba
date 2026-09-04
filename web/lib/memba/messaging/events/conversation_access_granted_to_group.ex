defmodule Memba.Messaging.Events.ConversationAccessGrantedToGroup do
  @moduledoc """
  Event raised when a conversation grants read or write access to a group.
  """

  @derive Jason.Encoder
  @enforce_keys [:conversation_id, :club_id, :group_id, :access_level]
  defstruct [:conversation_id, :club_id, :group_id, :access_level]
end
