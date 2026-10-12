defmodule Memba.Membership.PermissionQueriesTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.App
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.RemoveClubRoleFromMember
  alias Memba.Membership.Permissions
  alias Memba.Membership.Roles
  alias Memba.Membership.ClubCommands
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.AddMember
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.PermissionQueries

  test "has_permission?/3 checks backend projected member permissions" do
    club_id = Memba.ID.generate(:club)
    bootstrap_person_id = Memba.ID.generate(:person)
    bootstrap_membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)
    role_id = Roles.membership_administrator_role_id(club_id)
    permission = Permissions.club_manage_members()

    assert :ok =
             (with {:ok, command} <-
                     ClubCommands.prepare_create(
                       membership_club_attrs(
                         club_id: club_id,
                         name: "Kootenay Mountaineering Club"
                       )
                     ) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_create(%{
                       person_id: bootstrap_person_id,
                       name: "Bootstrap",
                       email: "bootstrap@example.com"
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert :ok =
             (with {:ok, command} <-
                     AddMember.prepare(%{
                       membership_id: bootstrap_membership_id,
                       club_id: club_id,
                       person_id: bootstrap_person_id
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_create(%{
                       person_id: person_id,
                       name: "Alice",
                       email: "alice@example.com"
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    assert :ok =
             (with {:ok, command} <-
                     AddMember.prepare(%{
                       membership_id: membership_id,
                       club_id: club_id,
                       person_id: person_id
                     }) do
                CommandDispatch.dispatch(command, consistency: :strong)
              end)

    refute PermissionQueries.has_permission?(club_id, person_id, permission)

    assert :ok =
             App.dispatch(
               %AssignClubRoleToMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id
               },
               consistency: :strong
             )

    assert PermissionQueries.has_permission?(club_id, person_id, permission)
    refute PermissionQueries.has_permission?("not-a-club-id", person_id, permission)
    refute PermissionQueries.has_permission?(club_id, "not-a-person-id", permission)
    refute PermissionQueries.has_permission?(club_id, person_id, "club.manage_trips")

    assert :ok =
             App.dispatch(
               %RemoveClubRoleFromMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id
               },
               consistency: :strong
             )

    refute PermissionQueries.has_permission?(club_id, person_id, permission)
  end
end
