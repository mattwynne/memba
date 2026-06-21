defmodule Memba.Messaging.Router do
  @moduledoc """
  Command router for Messaging commands.
  """

  use Commanded.Commands.Router

  alias Memba.Messaging.InboundEmailReceipt
  alias Memba.Messaging.Message
  alias Memba.Messaging.Commands.AcceptInboundClubEmail
  alias Memba.Messaging.Commands.PostMessageReply
  alias Memba.Messaging.Commands.RejectInboundClubEmail
  alias Memba.Messaging.Commands.ReportEmailDeliveryBounced
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelayed
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.ReportEmailDeliverySpamComplaint
  alias Memba.Messaging.Commands.ReceiveInboundEmail
  alias Memba.Messaging.Commands.SendMessage

  identify(InboundEmailReceipt, by: :inbound_email_id)
  identify(Message, by: :message_id)

  dispatch([ReceiveInboundEmail, AcceptInboundClubEmail, RejectInboundClubEmail],
    to: InboundEmailReceipt
  )

  dispatch(
    [
      SendMessage,
      PostMessageReply,
      ReportEmailDeliveryDelivered,
      ReportEmailDeliveryDelayed,
      ReportEmailDeliveryBounced,
      ReportEmailDeliverySpamComplaint
    ],
    to: Message
  )
end
