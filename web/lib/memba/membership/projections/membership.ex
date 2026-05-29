defmodule Memba.Membership.Projections.Membership do
  @moduledoc """
  Read model projection for an active club membership in the Membership context.
  """

  use Ecto.Schema

  @primary_key {:membership_id, :binary_id, autogenerate: false}
  schema "membership_memberships" do
    field :club_id, :binary_id
    field :person_id, :binary_id
    field :active, :boolean

    timestamps(type: :utc_datetime_usec)
  end
end
