defmodule Memba.Messaging.ConversationReferenceTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.ConversationReference

  test "root messages use their message id as the conversation id" do
    message_id = Memba.ID.generate(:message)

    assert ConversationReference.root_conversation_id(message_id) == message_id
  end

  test "direct replies point at the root conversation message" do
    conversation_id = Memba.ID.generate(:message)

    assert ConversationReference.reply_to_message_id(conversation_id) == conversation_id
  end
end
