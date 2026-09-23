defmodule Memba.Messaging.Projections.SystemAuthoritySubscriptionRevocationReceipt do
  @moduledoc "Durable receipt for a scoped system-authority subscription revocation."
  use Ecto.Schema

  @primary_key {:revocation_id, :string, autogenerate: false}
  schema "messaging_system_authority_subscription_revocation_receipts" do
    field :person_id, :string
    field :club_id, :string
    field :club_membership_id, :string
    field :authority_kind, :string
    field :authority_through_club_stream_version, :integer
    field :completed, :boolean, default: false
    timestamps(type: :utc_datetime_usec)
  end
end
