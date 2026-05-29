defmodule Memba.Messaging.Commands.SendMessage do
  @moduledoc """
  Command to send a message to a club's already-resolved recipients.

  The caller supplies the message aggregate identity as `message_id` and a list
  of resolved `Memba.Messaging.Recipient` values.
  """

  @enforce_keys [:message_id, :club_id, :sender_id, :subject, :body, :recipients]
  defstruct [:message_id, :club_id, :sender_id, :subject, :body, :recipients]
end
