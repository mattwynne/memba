defmodule Memba.Messaging.EmailDeliveryRequest do
  @moduledoc """
  Channel-neutral request handed to a email delivery provider.

  The first messaging slice sends email, but the request shape keeps the provider
  boundary focused on deliveries rather than an email-specific domain concept.
  It carries Memba's own message, delivery, and club identifiers so providers can
  attach correlation metadata without querying domain state.
  """

  @enforce_keys [
    :message_id,
    :club_id,
    :delivery_id,
    :outbound_message_id,
    :recipient_id,
    :recipient_name,
    :recipient_address,
    :sender_name,
    :sender_address,
    :channel,
    :subject,
    :body
  ]
  defstruct [
    :message_id,
    :club_id,
    :delivery_id,
    :outbound_message_id,
    :recipient_id,
    :recipient_name,
    :recipient_address,
    :audience_group_id,
    :club_name,
    :club_slug,
    :sender_name,
    :sender_address,
    :conversation_id,
    :reply_to_message_id,
    :in_reply_to_outbound_message_id,
    :references_outbound_message_ids,
    :conversation_url,
    :stop_follow_url,
    :reply_to_sender_name,
    :reply_to_body,
    :channel,
    :subject,
    :body
  ]

  @type t :: %__MODULE__{
          message_id: String.t(),
          club_id: String.t(),
          delivery_id: String.t(),
          outbound_message_id: String.t(),
          recipient_id: String.t(),
          recipient_name: String.t(),
          recipient_address: String.t(),
          audience_group_id: String.t() | nil,
          club_name: String.t() | nil,
          club_slug: String.t() | nil,
          sender_name: String.t(),
          sender_address: String.t(),
          conversation_id: String.t() | nil,
          reply_to_message_id: String.t() | nil,
          in_reply_to_outbound_message_id: String.t() | nil,
          references_outbound_message_ids: [String.t()] | nil,
          conversation_url: String.t() | nil,
          stop_follow_url: String.t() | nil,
          reply_to_sender_name: String.t() | nil,
          reply_to_body: String.t() | nil,
          channel: :email,
          subject: String.t(),
          body: String.t()
        }
end
