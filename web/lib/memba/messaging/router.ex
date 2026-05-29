defmodule Memba.Messaging.Router do
  @moduledoc """
  Command router for Messaging commands.
  """

  use Commanded.Commands.Router

  alias Memba.Messaging.Message
  alias Memba.Messaging.Commands.SendMessage

  identify(Message, by: :message_id)

  dispatch(SendMessage, to: Message)
end
