defmodule Memba.Membership.Projections.Membership do
  @moduledoc """
  Read model projection for a person's membership of a club.
  """

  use Ecto.Schema

  @primary_key {:membership_id, :binary_id, autogenerate: false}
  schema "membership_memberships" do
    field :club_id, :binary_id
    field :person_id, :binary_id
    field :active?, :boolean, source: :active

    timestamps(type: :utc_datetime_usec)
  end
end
