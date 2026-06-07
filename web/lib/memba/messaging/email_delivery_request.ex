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
    :recipient_id,
    :recipient_name,
    :recipient_address,
    :club_name,
    :sender_name,
    :sender_address,
    :channel,
    :subject,
    :body
  ]

  @type t :: %__MODULE__{
          message_id: String.t(),
          club_id: String.t(),
          delivery_id: String.t(),
          recipient_id: String.t(),
          recipient_name: String.t(),
          recipient_address: String.t(),
          club_name: String.t() | nil,
          sender_name: String.t(),
          sender_address: String.t(),
          channel: :email,
          subject: String.t(),
          body: String.t()
        }
end
