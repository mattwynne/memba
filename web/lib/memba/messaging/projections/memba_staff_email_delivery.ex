defmodule Memba.Messaging.Projections.MembaStaffEmailDelivery do
  @moduledoc """
  Memba-staff-facing deliverability read model for one email delivery.

  Unlike member-facing email deliveries, this projection keeps the detailed delivery
  status and the provider/channel reason text Memba staff need for diagnosis.
  """

  use Ecto.Schema

  @primary_key {:delivery_id, :binary_id, autogenerate: false}
  schema "messaging_memba_staff_email_deliveries" do
    field :message_id, :binary_id
    field :recipient_id, :binary_id
    field :recipient_name, :string
    field :recipient_address, :string
    field :channel, :string
    field :status, :string
    field :reason, :string
    field :message_subject, :string, virtual: true
    field :event_at, :utc_datetime_usec, virtual: true

    timestamps(type: :utc_datetime_usec)
  end
end
