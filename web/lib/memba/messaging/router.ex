defmodule Memba.Messaging.Router do
  @moduledoc """
  Command router for Messaging commands.
  """

  use Commanded.Commands.Router

  alias Memba.Messaging.Message
  alias Memba.Messaging.Commands.ReportEmailDeliveryBounced
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelayed
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.ReportEmailDeliveryOpened
  alias Memba.Messaging.Commands.ReportEmailDeliverySpamComplaint
  alias Memba.Messaging.Commands.SendMessage

  identify(Message, by: :message_id)

  dispatch(
    [
      SendMessage,
      ReportEmailDeliveryDelivered,
      ReportEmailDeliveryDelayed,
      ReportEmailDeliveryBounced,
      ReportEmailDeliverySpamComplaint,
      ReportEmailDeliveryOpened
    ],
    to: Message
  )
end
