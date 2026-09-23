defmodule Memba.Messaging.Projections.GroupMembershipSubscriptionRevocationReceipt do
  @moduledoc "Durable query receipt for a GroupMembership subscription revocation."
  use Ecto.Schema

  @primary_key {:revocation_id, :string, autogenerate: false}
  schema "messaging_group_membership_subscription_revocation_receipts" do
    field :person_id, :string
    field :group_membership_id, :string
    field :completed, :boolean, default: false
    timestamps(type: :utc_datetime_usec)
  end
end
