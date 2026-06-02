defmodule Memba.Messaging.Projections.EmailDelivery do
  @moduledoc """
  Read model projection for one email delivery belonging to a message.
  """

  use Ecto.Schema

  @primary_key {:delivery_id, :binary_id, autogenerate: false}
  schema "messaging_email_deliveries" do
    field :message_id, :binary_id
    field :recipient_id, :binary_id
    field :recipient_name, :string
    field :recipient_address, :string
    field :channel, :string
    field :status, :string

    timestamps(type: :utc_datetime_usec)
  end
end
