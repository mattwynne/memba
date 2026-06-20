defmodule Memba.Messaging.Projections.EmailDelivery do
  @moduledoc """
  Read model projection for one email delivery belonging to a message.
  """

  use Ecto.Schema

  @primary_key {:delivery_id, :string, autogenerate: false}
  schema "messaging_email_deliveries" do
    field :message_id, :string
    field :recipient_id, :string
    field :recipient_name, :string
    field :recipient_address, :string
    field :channel, :string
    field :status, :string
    field :attempt_count, :integer, default: 0
    field :latest_error, :string
    field :latest_detail, :string
    field :last_dispatch_attempted_at, :utc_datetime_usec
    field :sent_at, :utc_datetime_usec
    field :failed_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end
end
