defmodule Memba.Membership.AuthorizationTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Authorization
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Commands.RemoveMemberRole
  alias Memba.Membership.Permissions
  alias Memba.Membership.Roles

  test "has_permission?/3 reads the internal flattened member-permission projection" do
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)
    role_id = Roles.membership_administrator_role_id(club_id)
    permission = Permissions.club_manage_members()

    create_club!(club_id)
    create_person!(person_id)
    add_member!(membership_id, club_id, person_id)

    refute Authorization.has_permission?(club_id, person_id, permission)

    assert :ok =
             App.dispatch(
               %AssignMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id
               },
               consistency: :strong
             )

    assert Authorization.has_permission?(club_id, person_id, permission)
    refute Authorization.has_permission?("not-a-club-id", person_id, permission)
    refute Authorization.has_permission?(club_id, "not-a-person-id", permission)
    refute Authorization.has_permission?(club_id, person_id, "club.manage_trips")

    assert :ok =
             App.dispatch(
               %RemoveMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id
               },
               consistency: :strong
             )

    refute Authorization.has_permission?(club_id, person_id, permission)
  end

  defp create_club!(club_id) do
    assert :ok =
             Membership.create_club(
               membership_club_attrs(club_id: club_id, name: "Kootenay Mountaineering Club"),
               consistency: :strong
             )
  end

  defp create_person!(person_id) do
    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Alice", email: "alice@example.com"},
               consistency: :strong
             )
  end

  defp add_member!(membership_id, club_id, person_id) do
    assert :ok =
             Membership.add_member(
               %{membership_id: membership_id, club_id: club_id, person_id: person_id},
               consistency: :strong
             )
  end
end
