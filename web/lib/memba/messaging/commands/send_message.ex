defmodule Memba.Messaging.Commands.SendMessage do
  @moduledoc """
  Command to send a message to a club's already-resolved recipients.

  The caller supplies the message aggregate identity as `message_id` and a list
  of resolved `Memba.Messaging.Recipient` values.

  A message is also the write-model unit for a conversation entry. Root club
  messages omit `conversation_id`/`reply_to_message_id`; the aggregate records
  the root's `conversation_id` as its own `message_id`. Root messages may also
  carry the resolved `audience_group_id` so the aggregate can record the
  conversation access grant for that audience. Replies use their own
  `message_id`, reference the root via `conversation_id`, and may reference the
  immediate message being answered via `reply_to_message_id`.
  """

  @enforce_keys [:message_id, :club_id, :sender_id, :subject, :body, :recipients]
  defstruct [
    :message_id,
    :club_id,
    :sender_id,
    :audience_group_id,
    :conversation_id,
    :reply_to_message_id,
    :subject,
    :body,
    :recipients
  ]
end
