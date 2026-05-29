defmodule Memba.Membership do
  @moduledoc """
  Public query API for the Membership bounded context.
  """

  import Ecto.Query

  alias Memba.Membership.ActiveMember
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person
  alias Memba.Repo

  @doc """
  Fetch a projected club read model by caller-generated UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_club(club_id) do
    with {:ok, club_id} <- Ecto.UUID.cast(club_id) do
      Repo.get(Club, club_id)
    else
      :error -> nil
    end
  end

  @doc """
  Fetch a projected person read model by caller-generated UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_person(person_id) do
    with {:ok, person_id} <- Ecto.UUID.cast(person_id) do
      Repo.get(Person, person_id)
    else
      :error -> nil
    end
  end

  @doc """
  List active members of a projected club by caller-generated club UUID.

  Returns public `Memba.Membership.ActiveMember` structs containing the member
  identity, name, and email address needed by downstream contexts. Returns an
  empty list when the ID is absent, invalid, or has no active members.
  """
  def list_active_members_of_club(club_id) do
    with {:ok, club_id} <- Ecto.UUID.cast(club_id) do
      MembershipProjection
      |> join(:inner, [membership], person in Person,
        on: person.person_id == membership.person_id
      )
      |> where([membership, _person], membership.club_id == ^club_id)
      |> where([membership, _person], membership.active? == true)
      |> order_by([_membership, person],
        asc: person.name,
        asc: person.email,
        asc: person.person_id
      )
      |> select([_membership, person], %ActiveMember{
        id: person.person_id,
        name: person.name,
        email: person.email
      })
      |> Repo.all()
    else
      :error -> []
    end
  end

  @doc """
  Return whether a person is an active member of a club.

  Returns `false` when either ID is absent or invalid.
  """
  def active_member_of_club?(club_id, person_id) do
    with {:ok, club_id} <- Ecto.UUID.cast(club_id),
         {:ok, person_id} <- Ecto.UUID.cast(person_id) do
      MembershipProjection
      |> where([membership], membership.club_id == ^club_id)
      |> where([membership], membership.person_id == ^person_id)
      |> where([membership], membership.active? == true)
      |> Repo.exists?()
    else
      :error -> false
    end
  end
end
