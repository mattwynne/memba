defmodule Memba.Messaging.ConversationReference do
  @moduledoc """
  Encapsulates the Messaging conversation identity convention.

  Iteration 039 models a conversation as the root message plus replies. The root
  message ID is therefore the conversation ID, and direct replies reference that
  same root message.
  """

  @type message_id :: String.t()

  @spec root_conversation_id(message_id()) :: message_id()
  def root_conversation_id(message_id), do: message_id

  @spec reply_to_message_id(message_id()) :: message_id()
  def reply_to_message_id(conversation_id), do: conversation_id
end
