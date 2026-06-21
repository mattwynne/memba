defmodule Memba.Messaging.Events.MessageSent do
  @moduledoc """
  Event raised when a club message has been accepted for sending.
  """

  @derive Jason.Encoder
  @enforce_keys [:message_id, :club_id, :sender_id, :subject, :body]
  defstruct [
    :message_id,
    :club_id,
    :sender_id,
    :conversation_id,
    :reply_to_message_id,
    :subject,
    :body
  ]
end
