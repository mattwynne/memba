defmodule Memba.ProductionSmokeFixtures do
  @moduledoc """
  Ensures the production smoke-test membership fixture exists.

  The fixture is created through focused Membership command preparers and dispatch
  so the event store remains the source of truth and projections are repaired by
  normal projectors. It is idempotent and safe to run during every release migration.
  """

  alias Memba.ID
  alias Memba.Membership.{AddMember, ClubCommands, ClubGroupQueries, CommandDispatch}
  alias Memba.Membership.{PersonCommands, PersonQueries}
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
    case ClubGroupQueries.get_club_by_slug(@club_slug) do
      nil ->
        {:ok, command} =
          ClubCommands.prepare_create(%{
            club_id: ID.generate(:club),
            name: @club_name,
            slug: @club_slug
          })

        :ok = CommandDispatch.dispatch(command, consistency: :strong)
        ClubGroupQueries.get_club_by_slug(@club_slug)

      %{name: @club_name} = club ->
        club

      club ->
        {:ok, command} =
          ClubCommands.prepare_update(%{
            club_id: club.club_id,
            name: @club_name,
            slug: @club_slug
          })

        :ok = CommandDispatch.dispatch(command, consistency: :strong)
        ClubGroupQueries.get_club_by_slug(@club_slug)
    end
  end

  defp ensure_person! do
    case PersonQueries.get_person_by_email(@person_email) do
      nil ->
        {:ok, command} =
          PersonCommands.prepare_create(%{
            person_id: ID.generate(:person),
            name: @person_name,
            email: @person_email
          })

        :ok = CommandDispatch.dispatch(command, consistency: :strong)
        PersonQueries.get_person_by_email(@person_email)

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

        {:ok, command} =
          AddMember.prepare(%{
            membership_id: membership_id,
            club_id: club_id,
            person_id: person_id
          })

        :ok = CommandDispatch.dispatch(command, consistency: :strong)

        membership_id

      %{membership_id: membership_id} ->
        membership_id
    end
  end
end
