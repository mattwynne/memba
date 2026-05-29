defmodule Memba.Messaging.Router do
  @moduledoc """
  Command router for Messaging commands.
  """

  use Commanded.Commands.Router

  alias Memba.Messaging.Message
  alias Memba.Messaging.Commands.ReportDeliveryBounced
  alias Memba.Messaging.Commands.ReportDeliveryDelayed
  alias Memba.Messaging.Commands.ReportDeliveryDelivered
  alias Memba.Messaging.Commands.ReportDeliveryOpened
  alias Memba.Messaging.Commands.ReportDeliverySpamComplaint
  alias Memba.Messaging.Commands.SendMessage

  identify(Message, by: :message_id)

  dispatch(
    [
      SendMessage,
      ReportDeliveryDelivered,
      ReportDeliveryDelayed,
      ReportDeliveryBounced,
      ReportDeliverySpamComplaint,
      ReportDeliveryOpened
    ],
    to: Message
  )
end
