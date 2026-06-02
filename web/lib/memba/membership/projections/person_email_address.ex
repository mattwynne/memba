defmodule Memba.Membership.Projections.PersonEmailAddress do
  @moduledoc """
  Read model projection for an email address attached to a Membership person.
  """

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "membership_person_email_addresses" do
    field :person_id, :binary_id
    field :email, :string
    field :normalized_email, :string
    field :is_primary, :boolean, default: false

    timestamps(type: :utc_datetime_usec)
  end
end
