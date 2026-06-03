defmodule Memba.Messaging.Projections.InboundEmailSource do
  @moduledoc """
  Read model projection for provider inbound email source/status records.
  """

  use Ecto.Schema

  @primary_key {:inbound_email_id, :string, autogenerate: false}
  schema "messaging_inbound_email_sources" do
    field :provider, :string
    field :provider_message_id, :string
    field :provider_event_id, :string
    field :from_address, :string
    field :to_address, :string
    field :status, :string
    field :club_id, :binary_id
    field :sender_id, :binary_id
    field :message_id, :binary_id
    field :rejection_reason, :string
    field :rejection_email_delivery_reference, :string

    timestamps(type: :utc_datetime_usec)
  end
end
