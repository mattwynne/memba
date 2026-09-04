defmodule Memba.Membership.Projections.GroupMembership do
  @moduledoc """
  Read model projection for a current group membership in the Membership context.
  """

  use Ecto.Schema

  @primary_key false
  schema "membership_group_memberships" do
    field :club_id, :string
    field :group_id, :string
    field :membership_id, :string
    field :person_id, :string
    field :active, :boolean

    timestamps(type: :utc_datetime_usec)
  end
end
