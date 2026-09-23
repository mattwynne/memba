defmodule Memba.Membership.Projections.FirstClassGroupMembership do
  @moduledoc """
  Historical read model for first-class custom GroupMembership lifecycles.

  `club_membership_id` uses the existing `membership_id` database column. This
  qualified schema boundary does not introduce or translate a second club
  membership identity.
  """

  use Ecto.Schema

  @primary_key {:group_membership_id, :string, autogenerate: false}
  schema "membership_first_class_group_memberships" do
    field :club_id, :string
    field :group_id, :string
    field :club_membership_id, :string, source: :membership_id
    field :person_id, :string
    field :active, :boolean
    field :end_idempotency_key, :string
    field :end_reason, :string
  end
end
