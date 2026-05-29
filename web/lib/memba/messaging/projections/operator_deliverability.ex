defmodule Memba.Messaging.Projections.OperatorDeliverability do
  @moduledoc """
  Operator-facing deliverability read model for one recipient delivery.

  Unlike member-facing receipts, this projection keeps the detailed delivery
  status and the provider/channel reason text operators need for diagnosis.
  """

  use Ecto.Schema

  @primary_key {:delivery_id, :binary_id, autogenerate: false}
  schema "messaging_operator_deliverabilities" do
    field :message_id, :binary_id
    field :recipient_id, :binary_id
    field :recipient_name, :string
    field :recipient_address, :string
    field :channel, :string
    field :status, :string
    field :reason, :string

    timestamps(type: :utc_datetime_usec)
  end
end
