defmodule Memba.Membership.Projections.Membership do
  @moduledoc """
  Read model projection for an active club membership in the Membership context.
  """

  use Ecto.Schema

  @primary_key {:membership_id, :string, autogenerate: false}
  schema "membership_memberships" do
    field :club_id, :string
    field :person_id, :string
    field :active, :boolean

    timestamps(type: :utc_datetime_usec)
  end
end
