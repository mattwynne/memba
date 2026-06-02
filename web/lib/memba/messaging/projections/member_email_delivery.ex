defmodule Memba.Messaging.Projections.MemberEmailDelivery do
  @moduledoc """
  Member-facing receipt read model for one email delivery.

  The `status` field stores the simplified member-facing vocabulary rather
  than provider- or Memba-staff-facing delivery details. Current projections
  use `sent`, `delivered`, and `delivery problem`.
  """

  use Ecto.Schema

  @primary_key {:delivery_id, :binary_id, autogenerate: false}
  schema "messaging_member_email_deliveries" do
    field :message_id, :binary_id
    field :recipient_id, :binary_id
    field :recipient_name, :string
    field :status, :string

    timestamps(type: :utc_datetime_usec)
  end
end
