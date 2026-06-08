defmodule Memba.Membership.Projections.RoleAssignment do
  @moduledoc """
  Read model projection for a role assignment to a club membership.
  """

  use Ecto.Schema

  @primary_key false
  schema "membership_role_assignments" do
    field :club_id, :string
    field :membership_id, :string
    field :person_id, :string
    field :role_id, :string
    field :active, :boolean

    timestamps(type: :utc_datetime_usec)
  end
end
