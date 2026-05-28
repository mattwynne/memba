defmodule Memba.Membership.Projections.Club do
  @moduledoc """
  Read model projection for a club in the Membership bounded context.
  """

  use Ecto.Schema

  @primary_key {:club_id, :binary_id, autogenerate: false}
  schema "membership_clubs" do
    field :name, :string

    timestamps(type: :utc_datetime_usec)
  end
end
