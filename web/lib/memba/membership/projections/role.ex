defmodule Memba.Membership.Projections.Role do
  @moduledoc """
  Read model projection for a club-scoped role in the Membership context.
  """

  use Ecto.Schema

  @primary_key {:role_id, :string, autogenerate: false}
  schema "membership_roles" do
    field :club_id, :string
    field :role_key, :string
    field :name, :string

    timestamps(type: :utc_datetime_usec)
  end
end
