defmodule Memba.Membership.ClubReplayTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.Club
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.ClubMemberRemoved
  alias Memba.Membership.Events.ClubRoleAssignedToMember
  alias Memba.Membership.Events.ClubRoleRemovedFromMember
  alias Memba.Membership.Events.MemberAdded, as: LegacyMemberAdded
  alias Memba.Membership.Events.MemberRemoved, as: LegacyMemberRemoved
  alias Memba.Membership.Events.MemberRoleAssigned, as: LegacyMemberRoleAssigned
  alias Memba.Membership.Events.MemberRoleRemoved, as: LegacyMemberRoleRemoved
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups

  describe "historic Club stream replay" do
    test "hydrates the active club memberships from Everyone membership facts" do
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

    test "reconstructs active Admins from active club memberships and historic role facts" do
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

    test "keeps non-Everyone membership facts out of the active club memberships" do
      ids = replay_ids()
      custom_group_id = Memba.ID.generate(:group)
      membership_id = ids.first_membership_id
      person_id = ids.first_person_id

      club =
        replay(ids.club_id, [
          %GroupMemberAdded{
            club_id: ids.club_id,
            group_id: custom_group_id,
            membership_id: membership_id,
            person_id: person_id
          }
        ])

      assert_replay_state(club,
        active_memberships: %{},
        native_membership_ids: MapSet.new(),
        active_admin_membership_ids: MapSet.new()
      )

      assert %{
               {^custom_group_id, ^membership_id} => %{
                 person_id: ^person_id,
                 active: true
               }
             } = club.group_memberships
    end
  end

  describe "legacy Club member event replay" do
    test "supports historic MemberAdded, MemberRemoved, MemberRoleAssigned, and MemberRoleRemoved facts" do
      ids = replay_ids()

      club =
        replay(ids.club_id, [
          %LegacyMemberAdded{
            club_id: ids.club_id,
            membership_id: ids.first_membership_id,
            person_id: ids.first_person_id
          },
          %LegacyMemberRoleAssigned{
            club_id: ids.club_id,
            membership_id: ids.first_membership_id,
            person_id: ids.first_person_id,
            role_id: ids.admin_role_id
          },
          %LegacyMemberRoleRemoved{
            club_id: ids.club_id,
            membership_id: ids.first_membership_id,
            person_id: ids.first_person_id,
            role_id: ids.admin_role_id
          },
          %LegacyMemberRemoved{
            club_id: ids.club_id,
            membership_id: ids.first_membership_id,
            person_id: ids.first_person_id
          }
        ])

      assert_replay_state(club,
        active_memberships: %{},
        native_membership_ids: MapSet.new([ids.first_membership_id]),
        active_admin_membership_ids: MapSet.new()
      )
    end
  end

  describe "mixed native and compatibility Club stream replay" do
    test "delayed Everyone facts cannot override native membership lifecycle facts" do
      ids = replay_ids()

      club =
        replay(ids.club_id, [
          club_member_added(ids, ids.first_membership_id, ids.first_person_id),
          club_member_added(ids, ids.second_membership_id, ids.second_person_id),
          admin_role_assigned(ids, ids.first_membership_id, ids.first_person_id),
          club_member_removed(ids, ids.first_membership_id, ids.first_person_id),
          group_member_added(ids, ids.first_membership_id, ids.first_person_id),
          group_member_removed(ids, ids.second_membership_id, ids.second_person_id)
        ])

      assert_replay_state(club,
        active_memberships: %{ids.second_membership_id => ids.second_person_id},
        native_membership_ids: MapSet.new([ids.first_membership_id, ids.second_membership_id]),
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
          club_member_removed(ids, ids.first_membership_id, ids.first_person_id),
          group_member_added(ids, ids.first_membership_id, ids.first_person_id),
          group_member_removed(ids, ids.second_membership_id, ids.second_person_id),
          club_member_added(ids, ids.second_membership_id, ids.second_person_id),
          group_member_removed(ids, ids.second_membership_id, ids.second_person_id)
        ])

      assert_replay_state(club,
        active_memberships: %{ids.second_membership_id => ids.second_person_id},
        native_membership_ids: MapSet.new([ids.first_membership_id, ids.second_membership_id]),
        active_admin_membership_ids: MapSet.new()
      )
    end
  end

  describe "native membership lifecycle replay" do
    test "tracks the active club memberships and permanently marks IDs with native lifecycle facts" do
      ids = replay_ids()

      club =
        replay(ids.club_id, [
          club_member_added(ids, ids.first_membership_id, ids.first_person_id),
          club_member_added(ids, ids.second_membership_id, ids.second_person_id),
          club_member_removed(ids, ids.first_membership_id, ids.first_person_id)
        ])

      assert_replay_state(club,
        active_memberships: %{ids.second_membership_id => ids.second_person_id},
        native_membership_ids: MapSet.new([ids.first_membership_id, ids.second_membership_id]),
        active_admin_membership_ids: MapSet.new()
      )
    end

    test "derives active Admins by intersecting the native active club memberships with Admin assignments" do
      ids = replay_ids()

      assigned_before_activation =
        replay(ids.club_id, [
          admin_role_assigned(ids, ids.first_membership_id, ids.first_person_id)
        ])

      assert active_admin_membership_ids(assigned_before_activation) == MapSet.new()

      active_admin =
        Club.apply(
          assigned_before_activation,
          club_member_added(ids, ids.first_membership_id, ids.first_person_id)
        )

      assert active_admin_membership_ids(active_admin) ==
               MapSet.new([ids.first_membership_id])

      custom_role_id = Memba.ID.generate(:role)

      with_non_admin_assignment =
        active_admin
        |> Club.apply(club_member_added(ids, ids.second_membership_id, ids.second_person_id))
        |> Club.apply(%ClubRoleAssignedToMember{
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
          club_member_removed(ids, ids.first_membership_id, ids.first_person_id)
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

  defp club_member_added(ids, membership_id, person_id) do
    %ClubMemberAdded{
      club_id: ids.club_id,
      membership_id: membership_id,
      person_id: person_id
    }
  end

  defp club_member_removed(ids, membership_id, person_id) do
    %ClubMemberRemoved{
      club_id: ids.club_id,
      membership_id: membership_id,
      person_id: person_id
    }
  end

  defp admin_role_assigned(ids, membership_id, person_id) do
    %ClubRoleAssignedToMember{
      club_id: ids.club_id,
      membership_id: membership_id,
      person_id: person_id,
      role_id: ids.admin_role_id
    }
  end

  defp admin_role_removed(ids, membership_id, person_id) do
    %ClubRoleRemovedFromMember{
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
