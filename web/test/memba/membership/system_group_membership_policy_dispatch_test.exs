defmodule Memba.Membership.SystemGroupMembershipPolicyDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.App
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Commands.RemoveMember
  alias Memba.Membership.Commands.RemoveMemberRole
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups

  test "MemberAdded and MemberRemoved dispatch idempotent Everyone membership commands" do
    club_id = Memba.ID.generate(:club)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)
    everyone_group_id = SystemGroups.everyone_group_id(club_id)

    create_club(club_id)

    assert :ok =
             App.dispatch(
               %AddMember{club_id: club_id, membership_id: membership_id, person_id: person_id},
               consistency: :strong
             )

    assert_group_membership(club_id, everyone_group_id, membership_id, person_id, true)

    assert :ok =
             App.dispatch(%RemoveMember{membership_id: membership_id}, consistency: :strong)

    assert_group_membership(club_id, everyone_group_id, membership_id, person_id, false)
  end

  test "Admin role assignment and removal dispatch idempotent Admin group membership commands" do
    club_id = Memba.ID.generate(:club)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)
    admin_role_id = Roles.membership_administrator_role_id(club_id)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    create_club(club_id)
    add_member(club_id, membership_id, person_id)

    assert :ok =
             App.dispatch(
               %AssignMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: admin_role_id
               },
               consistency: :strong
             )

    assert_group_membership(club_id, admin_group_id, membership_id, person_id, true)

    assert :ok =
             App.dispatch(
               %RemoveMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: admin_role_id
               },
               consistency: :strong
             )

    assert_group_membership(club_id, admin_group_id, membership_id, person_id, false)
  end

  test "MemberRemoved dispatches removals for both Everyone and Admin system groups" do
    club_id = Memba.ID.generate(:club)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)
    admin_role_id = Roles.membership_administrator_role_id(club_id)
    everyone_group_id = SystemGroups.everyone_group_id(club_id)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    create_club(club_id)
    add_member(club_id, membership_id, person_id)

    assert :ok =
             App.dispatch(
               %AssignMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: admin_role_id
               },
               consistency: :strong
             )

    assert_group_membership(club_id, everyone_group_id, membership_id, person_id, true)
    assert_group_membership(club_id, admin_group_id, membership_id, person_id, true)

    assert :ok =
             App.dispatch(%RemoveMember{membership_id: membership_id}, consistency: :strong)

    assert_group_membership(club_id, everyone_group_id, membership_id, person_id, false)
    assert_group_membership(club_id, admin_group_id, membership_id, person_id, false)
  end

  test "non-Admin role lifecycle events do not alter Admin group membership" do
    club_id = Memba.ID.generate(:club)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)
    custom_role_id = Memba.ID.generate(:role)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    create_club(club_id)
    add_member(club_id, membership_id, person_id)

    assert :ok =
             App.dispatch(
               %DefineClubRole{
                 club_id: club_id,
                 role_id: custom_role_id,
                 role_key: "custom_membership_manager",
                 name: "Custom Membership Manager"
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %AssignMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: custom_role_id
               },
               consistency: :strong
             )

    refute_group_membership(club_id, admin_group_id, membership_id)

    assert :ok =
             App.dispatch(
               %RemoveMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: custom_role_id
               },
               consistency: :strong
             )

    refute_group_membership(club_id, admin_group_id, membership_id)
  end

  defp create_club(club_id) do
    assert :ok =
             App.dispatch(
               %CreateClub{
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club",
                 slug: "kmc"
               },
               consistency: :strong
             )
  end

  defp add_member(club_id, membership_id, person_id) do
    assert :ok =
             App.dispatch(
               %AddMember{club_id: club_id, membership_id: membership_id, person_id: person_id},
               consistency: :strong
             )

    await_group_membership_projector!()
  end

  defp assert_group_membership(club_id, group_id, membership_id, person_id, active?) do
    await_group_membership_projector!()

    assert %Club{
             group_memberships: %{
               {^group_id, ^membership_id} => %{
                 person_id: ^person_id,
                 active: ^active?
               }
             }
           } = App.aggregate_state(Club, club_id)
  end

  defp refute_group_membership(club_id, group_id, membership_id) do
    assert %Club{group_memberships: group_memberships} = App.aggregate_state(Club, club_id)
    refute Map.has_key?(group_memberships, {group_id, membership_id})
  end

  defp await_group_membership_projector! do
    Memba.ProjectionBarrier.await!([Memba.Membership.Projectors.GroupMembership], timeout: 1_000)
  end
end
