defmodule Memba.Messaging.Router do
  @moduledoc """
  Command router for Messaging commands.
  """

  use Commanded.Commands.Router

  alias Memba.Messaging.InboundEmailReceipt
  alias Memba.Messaging.Message
  alias Memba.Messaging.ConversationFollowers
  alias Memba.Messaging.Commands.AcceptInboundClubEmail
  alias Memba.Messaging.Commands.FollowConversation
  alias Memba.Messaging.Commands.GrantConversationAccessToGroup
  alias Memba.Messaging.Commands.PostMessageReply
  alias Memba.Messaging.Commands.RejectInboundClubEmail
  alias Memba.Messaging.Commands.ReportEmailDeliveryBounced
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelayed
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.ReportEmailDeliverySpamComplaint
  alias Memba.Messaging.Commands.ReceiveInboundEmail
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Commands.UnfollowConversation

  identify(InboundEmailReceipt, by: :inbound_email_id)
  identify(ConversationFollowers, by: :conversation_id)

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
    to: Message,
    identity: :message_id
  )

  dispatch(GrantConversationAccessToGroup, to: Message, identity: :conversation_id)

  dispatch([FollowConversation, UnfollowConversation], to: ConversationFollowers)
end
