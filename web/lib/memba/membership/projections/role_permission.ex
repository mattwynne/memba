defmodule Memba.Membership.Projections.RolePermission do
  @moduledoc """
  Read model projection for an app-defined permission granted to a club role.
  """

  use Ecto.Schema

  @primary_key false
  schema "membership_role_permissions" do
    field :club_id, :string
    field :role_id, :string
    field :permission, :string

    timestamps(type: :utc_datetime_usec)
  end
end
