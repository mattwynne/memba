defmodule Memba.Membership.Projections.PersonEmailAddress do
  @moduledoc """
  Read model projection for an email address attached to a Membership person.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Memba.ID
  alias Memba.Membership.EmailAddresses

  @primary_key {:id, :string, autogenerate: {Memba.ID, :generate, [:email_address]}}
  schema "membership_person_email_addresses" do
    field :person_id, :string
    field :email, :string
    field :normalized_email, :string
    field :is_primary, :boolean, default: false
    field :verified_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(email_address, attrs) do
    email_address
    |> cast(attrs, [:person_id, :email, :is_primary, :verified_at])
    |> put_id()
    |> validate_required([:person_id, :email, :is_primary])
    |> normalize_email()
    |> validate_required([:normalized_email])
    |> foreign_key_constraint(:person_id)
    |> unique_constraint(:normalized_email,
      name: :membership_person_email_addresses_normalized_email_index
    )
    |> unique_constraint(:person_id,
      name: :membership_person_email_addresses_one_primary_per_person_index,
      message: "already has a primary email address"
    )
  end

  defp put_id(changeset) do
    case get_field(changeset, :id) do
      nil -> put_change(changeset, :id, ID.generate(:email_address))
      _id -> changeset
    end
  end

  defp normalize_email(changeset) do
    case get_field(changeset, :email) do
      nil ->
        changeset

      email ->
        case EmailAddresses.normalize_email(email) do
          {:ok, %{email: email, normalized_email: normalized_email}} ->
            changeset
            |> put_change(:email, email)
            |> put_change(:normalized_email, normalized_email)

          {:error, :invalid_email} ->
            add_error(changeset, :email, "is invalid")
        end
    end
  end
end
