defmodule Memba.Membership.SystemGroupMembershipPolicyDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.EventStore
  alias Memba.Membership.App
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Commands.RemoveMember
  alias Memba.Membership.Commands.RemoveMemberRole
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Events.MemberAdded
  alias Memba.Membership.Events.MemberRemoved
  alias Memba.Membership.Events.MemberRoleAssigned
  alias Memba.Membership.Policies.SystemGroupMembership
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

  test "redelivered lifecycle events use Club group state rather than handler workflow memory" do
    club_id = Memba.ID.generate(:club)
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)
    admin_role_id = Roles.membership_administrator_role_id(club_id)
    everyone_group_id = SystemGroups.everyone_group_id(club_id)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    create_club(club_id)

    member_added = %MemberAdded{
      club_id: club_id,
      membership_id: membership_id,
      person_id: person_id
    }

    assert :ok = SystemGroupMembership.handle(member_added, %{})
    assert :ok = SystemGroupMembership.handle(member_added, %{})

    admin_role_assigned = %MemberRoleAssigned{
      club_id: club_id,
      membership_id: membership_id,
      person_id: person_id,
      role_id: admin_role_id
    }

    assert :ok = SystemGroupMembership.handle(admin_role_assigned, %{})
    assert :ok = SystemGroupMembership.handle(admin_role_assigned, %{})

    assert_group_membership(club_id, everyone_group_id, membership_id, person_id, true)
    assert_group_membership(club_id, admin_group_id, membership_id, person_id, true)

    member_removed = %MemberRemoved{
      club_id: club_id,
      membership_id: membership_id,
      person_id: person_id
    }

    assert :ok = SystemGroupMembership.handle(member_removed, %{})
    assert :ok = SystemGroupMembership.handle(member_removed, %{})

    assert_group_membership(club_id, everyone_group_id, membership_id, person_id, false)
    assert_group_membership(club_id, admin_group_id, membership_id, person_id, false)

    club_events = recorded_events(club_id)

    assert count_group_events(club_events, GroupMemberAdded, everyone_group_id, membership_id) ==
             1

    assert count_group_events(club_events, GroupMemberAdded, admin_group_id, membership_id) == 1

    assert count_group_events(club_events, GroupMemberRemoved, everyone_group_id, membership_id) ==
             1

    assert count_group_events(club_events, GroupMemberRemoved, admin_group_id, membership_id) == 1
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

  defp recorded_events(stream_uuid) do
    stream_uuid
    |> then(&EventStore.stream_forward(App, &1))
    |> Enum.to_list()
  end

  defp count_group_events(events, event_module, group_id, membership_id) do
    Enum.count(events, fn recorded_event ->
      match?(
        %{__struct__: ^event_module, group_id: ^group_id, membership_id: ^membership_id},
        recorded_event.data
      )
    end)
  end

  defp await_group_membership_projector! do
    Memba.ProjectionBarrier.await!([Memba.Membership.Projectors.GroupMembership], timeout: 1_000)
  end
end
