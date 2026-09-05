defmodule Memba.Membership.Projections.Group do
  @moduledoc """
  Read model projection for a club-scoped conversation group in the Membership context.
  """

  use Ecto.Schema

  @primary_key {:group_id, :string, autogenerate: false}
  schema "membership_groups" do
    field :club_id, :string
    field :group_key, :string
    field :email_slug, :string
    field :name, :string

    timestamps(type: :utc_datetime_usec)
  end
end
