defmodule Memba.Membership.PersonQueries do
  @moduledoc """
  Read-side queries for projected Membership people and their contact addresses.

  This module reads projections only; Membership remains the public API boundary.
  """

  import Ecto.Query

  alias Memba.ID
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person
  alias Memba.Membership.Projections.PersonEmailAddress
  alias Memba.Repo

  def get_person(person_id) do
    with {:ok, person_id} <- ID.cast(:person, person_id) do
      Repo.get(Person, person_id)
    else
      :error -> nil
    end
  end

  def get_person_by_email(email), do: find_person_by_email(email, false)
  def get_verified_person_by_email(email), do: find_person_by_email(email, true)

  defp find_person_by_email(email, verified?) do
    case normalize_email(email) do
      nil ->
        nil

      normalized_email ->
        Person
        |> join(:inner, [person], email_address in PersonEmailAddress,
          on: email_address.person_id == person.person_id
        )
        |> where([_person, email_address], email_address.normalized_email == ^normalized_email)
        |> require_verified_email(verified?)
        |> limit(1)
        |> Repo.one()
    end
  end

  defp require_verified_email(query, false), do: query

  defp require_verified_email(query, true) do
    where(query, [_person, email_address], not is_nil(email_address.verified_at))
  end

  def list_people do
    Person
    |> order_by([person], asc: person.name, asc: person.person_id)
    |> Repo.all()
  end

  def list_operator_people do
    people = list_people()
    person_ids = Enum.map(people, & &1.person_id)
    email_summaries = person_email_summaries(person_ids)
    membership_summaries = person_membership_summaries(person_ids)

    Enum.map(people, fn person ->
      emails = Map.get(email_summaries, person.person_id, %{alternate_emails: []})

      %{
        person_id: person.person_id,
        name: person.name,
        primary_email: Map.get(emails, :primary_email) || person.email,
        alternate_emails: Map.get(emails, :alternate_emails, []),
        memberships: Map.get(membership_summaries, person.person_id, [])
      }
    end)
  end

  def list_person_contact_summaries(person_ids) when is_list(person_ids) do
    person_ids = cast_person_ids(person_ids)

    if person_ids == [] do
      %{}
    else
      email_summaries = person_email_summaries(person_ids)

      Person
      |> where([person], person.person_id in ^person_ids)
      |> select([person], %{
        person_id: person.person_id,
        name: person.name,
        email: person.email
      })
      |> Repo.all()
      |> Map.new(fn person ->
        emails = Map.get(email_summaries, person.person_id, %{})

        {person.person_id,
         %{
           person_id: person.person_id,
           name: person.name,
           primary_email: Map.get(emails, :primary_email) || person.email
         }}
      end)
    end
  end

  def list_person_contact_summaries(_person_ids), do: %{}

  def get_person_primary_email(person_id) do
    with {:ok, person_id} <- ID.cast(:person, person_id) do
      PersonEmailAddress
      |> where([email_address], email_address.person_id == ^person_id)
      |> where([email_address], email_address.is_primary == true)
      |> select([email_address], email_address.email)
      |> Repo.one()
    else
      :error -> nil
    end
  end

  def list_person_alternate_emails(person_id) do
    with {:ok, person_id} <- ID.cast(:person, person_id) do
      PersonEmailAddress
      |> where([email_address], email_address.person_id == ^person_id)
      |> where([email_address], email_address.is_primary == false)
      |> order_by([email_address], asc: email_address.email, asc: email_address.id)
      |> select([email_address], email_address.email)
      |> Repo.all()
    else
      :error -> []
    end
  end

  def list_person_email_addresses(person_id) do
    with {:ok, person_id} <- ID.cast(:person, person_id) do
      PersonEmailAddress
      |> where([email_address], email_address.person_id == ^person_id)
      |> order_by([email_address],
        desc: email_address.is_primary,
        asc: email_address.email,
        asc: email_address.id
      )
      |> select([email_address], %{
        email: email_address.email,
        normalized_email: email_address.normalized_email,
        primary?: email_address.is_primary,
        verified_at: email_address.verified_at
      })
      |> Repo.all()
    else
      :error -> []
    end
  end

  defp person_email_summaries([]), do: %{}

  defp person_email_summaries(person_ids) do
    PersonEmailAddress
    |> where([email_address], email_address.person_id in ^person_ids)
    |> order_by([email_address],
      desc: email_address.is_primary,
      asc: email_address.email,
      asc: email_address.id
    )
    |> select([email_address], %{
      person_id: email_address.person_id,
      email: email_address.email,
      primary?: email_address.is_primary
    })
    |> Repo.all()
    |> Enum.group_by(& &1.person_id)
    |> Map.new(fn {person_id, email_addresses} ->
      primary_email =
        email_addresses
        |> Enum.find(& &1.primary?)
        |> case do
          nil -> nil
          email_address -> email_address.email
        end

      alternate_emails =
        for %{primary?: false, email: email} <- email_addresses do
          email
        end

      {person_id, %{primary_email: primary_email, alternate_emails: alternate_emails}}
    end)
  end

  defp person_membership_summaries([]), do: %{}

  defp person_membership_summaries(person_ids) do
    MembershipProjection
    |> join(:left, [membership], club in Club, on: club.club_id == membership.club_id)
    |> where([membership, _club], membership.person_id in ^person_ids)
    |> where([membership, _club], membership.active == true)
    |> order_by([membership, club],
      asc: club.name,
      asc: club.club_id,
      asc: membership.membership_id
    )
    |> select([membership, club], %{
      person_id: membership.person_id,
      membership_id: membership.membership_id,
      club_id: membership.club_id,
      club_name: club.name,
      club_slug: club.slug
    })
    |> Repo.all()
    |> Enum.group_by(& &1.person_id)
  end

  defp cast_person_ids(ids) do
    ids
    |> Enum.reduce([], fn id, valid_ids ->
      case ID.cast(:person, id) do
        {:ok, id} -> [id | valid_ids]
        :error -> valid_ids
      end
    end)
    |> Enum.uniq()
    |> Enum.reverse()
  end

  # Keep read lookup normalization distinct from write-side address validation:
  # lookup historically accepts any nonblank string after trim/downcase.
  defp normalize_email(email) when is_binary(email) do
    case email |> String.trim() |> String.downcase() do
      "" -> nil
      normalized_email -> normalized_email
    end
  end

  defp normalize_email(_email), do: nil
end
