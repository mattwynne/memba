defmodule Memba.MembershipFixtures do
  @moduledoc """
  Shared fixtures for Membership projection tests.
  """

  alias Memba.Membership.EmailAddresses
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Person
  alias Memba.Membership.Projections.PersonEmailAddress
  alias Memba.Membership.Slug
  alias Memba.Repo

  def membership_club_attrs(attrs \\ []) when is_list(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, &Ecto.UUID.generate/0)

    name =
      Keyword.get(attrs, :name, Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club"))

    %{
      club_id: club_id,
      name: name,
      slug: Keyword.get_lazy(attrs, :slug, fn -> membership_club_slug(name, club_id) end)
    }
  end

  def membership_club_slug(name, club_id) when is_binary(name) and is_binary(club_id) do
    suffix =
      club_id
      |> String.replace("-", "")
      |> String.slice(0, 8)

    max_base_length = Slug.max_length() - String.length(suffix) - 1

    base =
      name
      |> Slug.default_from_name()
      |> String.slice(0, max_base_length)
      |> String.trim("-")

    case base do
      "" -> suffix
      base -> "#{base}-#{suffix}"
    end
  end

  def insert_membership_club!(attrs \\ []) when is_list(attrs) do
    attrs = membership_club_attrs(attrs)

    Repo.insert!(%Club{
      club_id: attrs.club_id,
      name: attrs.name,
      slug: attrs.slug
    })
  end

  def membership_person_attrs(attrs \\ []) when is_list(attrs) do
    person_id = Keyword.get_lazy(attrs, :person_id, &Ecto.UUID.generate/0)

    %{
      person_id: person_id,
      name: Keyword.get(attrs, :name, "Test Member"),
      email: Keyword.fetch!(attrs, :email)
    }
  end

  def insert_membership_person!(attrs) when is_list(attrs) do
    attrs = membership_person_attrs(attrs)

    case existing_membership_person(attrs.email) do
      nil ->
        person =
          Repo.insert!(%Person{
            person_id: attrs.person_id,
            name: attrs.name,
            email: attrs.email
          })

        insert_membership_person_email_address!(
          person_id: attrs.person_id,
          email: attrs.email,
          is_primary: true
        )

        person

      %Person{} = person ->
        person
    end
  end

  def insert_membership_person_email_address!(attrs) when is_list(attrs) do
    attrs = Map.new(attrs)

    %PersonEmailAddress{}
    |> PersonEmailAddress.changeset(%{
      person_id: Map.fetch!(attrs, :person_id),
      email: Map.fetch!(attrs, :email),
      is_primary: Map.get(attrs, :is_primary, false)
    })
    |> Repo.insert!()
  end

  defp existing_membership_person(email) do
    with {:ok, %{normalized_email: normalized_email}} <- EmailAddresses.normalize_email(email),
         %PersonEmailAddress{person_id: person_id} <-
           Repo.get_by(PersonEmailAddress, normalized_email: normalized_email) do
      Repo.get!(Person, person_id)
    else
      _not_found -> nil
    end
  end
end
