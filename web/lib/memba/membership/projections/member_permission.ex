defmodule Memba.Membership.Projections.MemberPermission do
  @moduledoc """
  Flattened read model projection for currently active permissions held by members.
  """

  use Ecto.Schema

  @primary_key false
  schema "membership_member_permissions" do
    field :club_id, :string
    field :membership_id, :string
    field :person_id, :string
    field :permission, :string
    field :grant_count, :integer

    timestamps(type: :utc_datetime_usec)
  end
end
