defmodule Memba.Membership.ClubReplayTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.Club
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Events.MemberAdded
  alias Memba.Membership.Events.MemberRemoved
  alias Memba.Membership.Events.MemberRoleAssigned
  alias Memba.Membership.Events.MemberRoleRemoved
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups

  describe "historic Club stream replay" do
    @describetag skip: "iteration 059 task 005 implements Everyone compatibility replay"

    test "hydrates the active roster from Everyone membership facts" do
      ids = replay_ids()

      club =
        replay(ids.club_id, [
          group_member_added(ids, ids.first_membership_id, ids.first_person_id),
          group_member_added(ids, ids.second_membership_id, ids.second_person_id),
          group_member_removed(ids, ids.second_membership_id, ids.second_person_id)
        ])

      assert_replay_state(club,
        active_memberships: %{ids.first_membership_id => ids.first_person_id},
        native_membership_ids: MapSet.new(),
        active_admin_membership_ids: MapSet.new()
      )
    end

    test "reconstructs active Admins from active roster and historic role facts" do
      ids = replay_ids()

      assigned_before_membership =
        replay(ids.club_id, [
          admin_role_assigned(ids, ids.first_membership_id, ids.first_person_id)
        ])

      assert active_admin_membership_ids(assigned_before_membership) == MapSet.new()

      active_admin =
        Club.apply(
          assigned_before_membership,
          group_member_added(ids, ids.first_membership_id, ids.first_person_id)
        )

      assert active_admin_membership_ids(active_admin) ==
               MapSet.new([ids.first_membership_id])

      role_removed =
        Club.apply(
          active_admin,
          admin_role_removed(ids, ids.first_membership_id, ids.first_person_id)
        )

      assert active_admin_membership_ids(role_removed) == MapSet.new()

      inactive_admin =
        role_removed
        |> Club.apply(admin_role_assigned(ids, ids.first_membership_id, ids.first_person_id))
        |> Club.apply(group_member_removed(ids, ids.first_membership_id, ids.first_person_id))

      assert active_admin_membership_ids(inactive_admin) == MapSet.new()

      assert Map.has_key?(
               inactive_admin.role_assignments,
               {ids.first_membership_id, ids.admin_role_id}
             )
    end
  end

  describe "mixed native and compatibility Club stream replay" do
    @describetag skip: "iteration 059 task 005 implements Everyone compatibility replay"

    test "delayed Everyone facts cannot override native membership lifecycle facts" do
      ids = replay_ids()

      club =
        replay(ids.club_id, [
          member_added(ids, ids.first_membership_id, ids.first_person_id),
          member_added(ids, ids.second_membership_id, ids.second_person_id),
          admin_role_assigned(ids, ids.first_membership_id, ids.first_person_id),
          member_removed(ids, ids.first_membership_id, ids.first_person_id),
          group_member_added(ids, ids.first_membership_id, ids.first_person_id),
          group_member_removed(ids, ids.second_membership_id, ids.second_person_id)
        ])

      assert_replay_state(club,
        active_memberships: %{ids.second_membership_id => ids.second_person_id},
        native_membership_ids:
          MapSet.new([ids.first_membership_id, ids.second_membership_id]),
        active_admin_membership_ids: MapSet.new()
      )

      first_group_membership = {ids.everyone_group_id, ids.first_membership_id}
      second_group_membership = {ids.everyone_group_id, ids.second_membership_id}

      assert %{
               ^first_group_membership => %{active: true},
               ^second_group_membership => %{active: false}
             } = club.group_memberships
    end

    test "the first native fact permanently supersedes earlier Everyone compatibility state" do
      ids = replay_ids()

      club =
        replay(ids.club_id, [
          group_member_added(ids, ids.first_membership_id, ids.first_person_id),
          member_removed(ids, ids.first_membership_id, ids.first_person_id),
          group_member_added(ids, ids.first_membership_id, ids.first_person_id),
          group_member_removed(ids, ids.second_membership_id, ids.second_person_id),
          member_added(ids, ids.second_membership_id, ids.second_person_id),
          group_member_removed(ids, ids.second_membership_id, ids.second_person_id)
        ])

      assert_replay_state(club,
        active_memberships: %{ids.second_membership_id => ids.second_person_id},
        native_membership_ids:
          MapSet.new([ids.first_membership_id, ids.second_membership_id]),
        active_admin_membership_ids: MapSet.new()
      )
    end
  end

  describe "native membership lifecycle replay" do
    test "tracks the active roster and permanently marks IDs with native lifecycle facts" do
      ids = replay_ids()

      club =
        replay(ids.club_id, [
          member_added(ids, ids.first_membership_id, ids.first_person_id),
          member_added(ids, ids.second_membership_id, ids.second_person_id),
          member_removed(ids, ids.first_membership_id, ids.first_person_id)
        ])

      assert_replay_state(club,
        active_memberships: %{ids.second_membership_id => ids.second_person_id},
        native_membership_ids:
          MapSet.new([ids.first_membership_id, ids.second_membership_id]),
        active_admin_membership_ids: MapSet.new()
      )
    end

    test "derives active Admins by intersecting the native roster with Admin assignments" do
      ids = replay_ids()

      assigned_before_activation =
        replay(ids.club_id, [
          admin_role_assigned(ids, ids.first_membership_id, ids.first_person_id)
        ])

      assert active_admin_membership_ids(assigned_before_activation) == MapSet.new()

      active_admin =
        Club.apply(
          assigned_before_activation,
          member_added(ids, ids.first_membership_id, ids.first_person_id)
        )

      assert active_admin_membership_ids(active_admin) ==
               MapSet.new([ids.first_membership_id])

      custom_role_id = Memba.ID.generate(:role)

      with_non_admin_assignment =
        active_admin
        |> Club.apply(member_added(ids, ids.second_membership_id, ids.second_person_id))
        |> Club.apply(%MemberRoleAssigned{
          club_id: ids.club_id,
          membership_id: ids.second_membership_id,
          person_id: ids.second_person_id,
          role_id: custom_role_id
        })

      assert active_admin_membership_ids(with_non_admin_assignment) ==
               MapSet.new([ids.first_membership_id])

      role_removed =
        Club.apply(
          with_non_admin_assignment,
          admin_role_removed(ids, ids.first_membership_id, ids.first_person_id)
        )

      assert active_admin_membership_ids(role_removed) == MapSet.new()

      reassigned_admin =
        Club.apply(
          role_removed,
          admin_role_assigned(ids, ids.first_membership_id, ids.first_person_id)
        )

      assert active_admin_membership_ids(reassigned_admin) ==
               MapSet.new([ids.first_membership_id])

      inactive_admin =
        Club.apply(
          reassigned_admin,
          member_removed(ids, ids.first_membership_id, ids.first_person_id)
        )

      assert active_admin_membership_ids(inactive_admin) == MapSet.new()

      assert Map.has_key?(
               inactive_admin.role_assignments,
               {ids.first_membership_id, ids.admin_role_id}
             )
    end
  end

  defp replay(club_id, events) do
    creation_events =
      Club.execute(%Club{}, %CreateClub{
        club_id: club_id,
        name: "Historic Club",
        slug: "historic-club"
      })

    Enum.reduce(creation_events ++ events, %Club{}, fn event, club ->
      Club.apply(club, event)
    end)
  end

  defp assert_replay_state(club, expected) do
    assert Map.fetch!(club, :active_memberships) ==
             Keyword.fetch!(expected, :active_memberships)

    assert Map.fetch!(club, :native_membership_ids) ==
             Keyword.fetch!(expected, :native_membership_ids)

    assert active_admin_membership_ids(club) ==
             Keyword.fetch!(expected, :active_admin_membership_ids)
  end

  defp active_admin_membership_ids(club) do
    Map.fetch!(club, :active_admin_membership_ids)
  end

  defp group_member_added(ids, membership_id, person_id) do
    %GroupMemberAdded{
      club_id: ids.club_id,
      group_id: ids.everyone_group_id,
      membership_id: membership_id,
      person_id: person_id
    }
  end

  defp group_member_removed(ids, membership_id, person_id) do
    %GroupMemberRemoved{
      club_id: ids.club_id,
      group_id: ids.everyone_group_id,
      membership_id: membership_id,
      person_id: person_id
    }
  end

  defp member_added(ids, membership_id, person_id) do
    %MemberAdded{
      club_id: ids.club_id,
      membership_id: membership_id,
      person_id: person_id
    }
  end

  defp member_removed(ids, membership_id, person_id) do
    %MemberRemoved{
      club_id: ids.club_id,
      membership_id: membership_id,
      person_id: person_id
    }
  end

  defp admin_role_assigned(ids, membership_id, person_id) do
    %MemberRoleAssigned{
      club_id: ids.club_id,
      membership_id: membership_id,
      person_id: person_id,
      role_id: ids.admin_role_id
    }
  end

  defp admin_role_removed(ids, membership_id, person_id) do
    %MemberRoleRemoved{
      club_id: ids.club_id,
      membership_id: membership_id,
      person_id: person_id,
      role_id: ids.admin_role_id
    }
  end

  defp replay_ids do
    club_id = Memba.ID.generate(:club)

    %{
      club_id: club_id,
      admin_role_id: Roles.membership_administrator_role_id(club_id),
      everyone_group_id: SystemGroups.everyone_group_id(club_id),
      first_membership_id: Memba.ID.generate(:membership),
      first_person_id: Memba.ID.generate(:person),
      second_membership_id: Memba.ID.generate(:membership),
      second_person_id: Memba.ID.generate(:person)
    }
  end
end
