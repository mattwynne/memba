defmodule Memba.Messaging.Router do
  @moduledoc """
  Command router for Messaging commands.
  """

  use Commanded.Commands.Router

  alias Memba.Messaging.InboundEmailReceipt
  alias Memba.Messaging.Message
  alias Memba.Messaging.PersonConversationSubscriptions
  alias Memba.Messaging.Commands.AcceptInboundClubEmail
  alias Memba.Messaging.Commands.AuthorizePersonConversationSubscriptionIntent
  alias Memba.Messaging.Commands.CancelPersonConversationSubscriptionIntent
  alias Memba.Messaging.Commands.EndPersonConversationSubscription
  alias Memba.Messaging.Commands.GrantConversationAccessToGroup
  alias Memba.Messaging.Commands.GrantInitialConversationAccessToGroup
  alias Memba.Messaging.Commands.PostMessageReply
  alias Memba.Messaging.Commands.RejectInboundClubEmail
  alias Memba.Messaging.Commands.ReportEmailDeliveryBounced
  alias Memba.Messaging.Commands.RevokeConversationAccessFromGroup
  alias Memba.Messaging.Commands.RevokeGroupMembershipConversationSubscriptions
  alias Memba.Messaging.Commands.RevokeSystemConversationSubscriptions
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelayed
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.ReportEmailDeliverySpamComplaint
  alias Memba.Messaging.Commands.ReceiveInboundEmail
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Commands.StartPersonConversationSubscriptionIntent

  identify(InboundEmailReceipt, by: :inbound_email_id)

  identify(PersonConversationSubscriptions,
    by: :person_id,
    prefix: "person-conversation-subscriptions-"
  )

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

  dispatch(
    [
      GrantConversationAccessToGroup,
      GrantInitialConversationAccessToGroup,
      RevokeConversationAccessFromGroup
    ],
    to: Message,
    identity: :conversation_id
  )

  dispatch(
    [
      StartPersonConversationSubscriptionIntent,
      CancelPersonConversationSubscriptionIntent,
      EndPersonConversationSubscription,
      RevokeGroupMembershipConversationSubscriptions,
      RevokeSystemConversationSubscriptions
    ],
    to: PersonConversationSubscriptions
  )

  dispatch(AuthorizePersonConversationSubscriptionIntent,
    to: PersonConversationSubscriptions,
    before_execute: :revalidate_authority_before_execute
  )
end
