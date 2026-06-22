defmodule Memba.ProductionSmokeFixtures do
  @moduledoc """
  Ensures the production smoke-test membership fixture exists.

  The fixture is intentionally created through the Membership command API so the
  event store remains the source of truth and projections are repaired by normal
  projectors. It is idempotent and safe to run during every release migration.
  """

  alias Memba.ID
  alias Memba.Membership
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Repo

  @club_name "Smoke Test Club"
  @club_slug "test"
  @person_name "Smoke Tester"
  @person_email "test@memba.io"

  def ensure! do
    club = ensure_club!()
    person = ensure_person!()
    membership_id = ensure_membership!(club.club_id, person.person_id)

    %{
      club_id: club.club_id,
      club_name: club.name,
      club_slug: club.slug,
      person_id: person.person_id,
      person_name: person.name,
      email: @person_email,
      membership_id: membership_id
    }
  end

  defp ensure_club! do
    case Membership.get_club_by_slug(@club_slug) do
      nil ->
        :ok =
          Membership.create_club(
            %{club_id: ID.generate(:club), name: @club_name, slug: @club_slug},
            consistency: :strong
          )

        Membership.get_club_by_slug(@club_slug)

      %{name: @club_name} = club ->
        club

      club ->
        :ok =
          Membership.update_club(
            %{club_id: club.club_id, name: @club_name, slug: @club_slug},
            consistency: :strong
          )

        Membership.get_club_by_slug(@club_slug)
    end
  end

  defp ensure_person! do
    case Membership.get_person_by_email(@person_email) do
      nil ->
        :ok =
          Membership.create_person(
            %{person_id: ID.generate(:person), name: @person_name, email: @person_email},
            consistency: :strong
          )

        Membership.get_person_by_email(@person_email)

      person ->
        person
    end
  end

  defp ensure_membership!(club_id, person_id) do
    case Repo.get_by(MembershipProjection,
           club_id: club_id,
           person_id: person_id,
           active: true
         ) do
      nil ->
        membership_id = ID.generate(:membership)

        :ok =
          Membership.add_member(
            %{membership_id: membership_id, club_id: club_id, person_id: person_id},
            consistency: :strong
          )

        membership_id

      %{membership_id: membership_id} ->
        membership_id
    end
  end
end
