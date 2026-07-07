defmodule Memba.Messaging.Projections.MemberEmailDelivery do
  @moduledoc """
  Member-facing receipt read model for one email delivery.

  The `status` field stores the simplified ADR 0006 vocabulary rather
  than provider- or Memba-staff-facing delivery details.
  """

  use Ecto.Schema

  @primary_key {:delivery_id, :string, autogenerate: false}
  schema "messaging_member_email_deliveries" do
    field :message_id, :string
    field :recipient_id, :string
    field :recipient_name, :string
    field :status, :string
    field :reason, :string, virtual: true

    timestamps(type: :utc_datetime_usec)
  end
end
