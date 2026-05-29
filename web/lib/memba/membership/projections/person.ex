defmodule Memba.Membership.Projections.Person do
  @moduledoc """
  Read model projection for a person in the Membership bounded context.
  """

  use Ecto.Schema

  @primary_key {:person_id, :binary_id, autogenerate: false}
  schema "membership_people" do
    field :name, :string
    field :email, :string

    timestamps(type: :utc_datetime_usec)
  end
end
