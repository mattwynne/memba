defmodule Memba.Messaging.DeliveryRequest do
  @moduledoc """
  Channel-neutral request handed to a delivery provider.

  The first messaging slice sends email, but the request shape keeps the provider
  boundary focused on deliveries rather than an email-specific domain concept.
  """

  @enforce_keys [
    :message_id,
    :delivery_id,
    :recipient_id,
    :recipient_name,
    :recipient_address,
    :channel,
    :subject,
    :body
  ]
  defstruct [
    :message_id,
    :delivery_id,
    :recipient_id,
    :recipient_name,
    :recipient_address,
    :channel,
    :subject,
    :body
  ]

  @type t :: %__MODULE__{
          message_id: Ecto.UUID.t(),
          delivery_id: Ecto.UUID.t(),
          recipient_id: Ecto.UUID.t(),
          recipient_name: String.t(),
          recipient_address: String.t(),
          channel: :email,
          subject: String.t(),
          body: String.t()
        }
end
