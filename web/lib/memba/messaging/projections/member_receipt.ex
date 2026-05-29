defmodule Memba.Messaging.Projections.MemberReceipt do
  @moduledoc """
  Member-facing receipt read model for one recipient delivery.

  The `receipt_status` field stores the simplified ADR 0006 vocabulary rather
  than provider- or operator-facing delivery details.
  """

  use Ecto.Schema

  @primary_key {:delivery_id, :binary_id, autogenerate: false}
  schema "messaging_member_receipts" do
    field :message_id, :binary_id
    field :recipient_id, :binary_id
    field :recipient_name, :string
    field :receipt_status, :string

    timestamps(type: :utc_datetime_usec)
  end
end
