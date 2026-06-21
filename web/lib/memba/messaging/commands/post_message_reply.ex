defmodule Memba.Messaging.Commands.PostMessageReply do
  @moduledoc """
  Command to post a reply to an existing club-message conversation.

  The caller supplies the reply message aggregate identity as `message_id` and
  references the root message with `conversation_id`. The reply inherits its
  subject and club from the root message before dispatch; recipients are still
  resolved by the Messaging application service and included on the command per
  the existing message-send boundary.
  """

  @enforce_keys [
    :message_id,
    :club_id,
    :sender_id,
    :conversation_id,
    :reply_to_message_id,
    :subject,
    :body,
    :recipients
  ]
  defstruct [
    :message_id,
    :club_id,
    :sender_id,
    :conversation_id,
    :reply_to_message_id,
    :subject,
    :body,
    :recipients
  ]
end
