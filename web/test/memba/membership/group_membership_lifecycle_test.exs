defmodule Memba.Membership.GroupMembershipLifecycleTest do
  use ExUnit.Case, async: true

  alias Memba.ID
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.AddCustomGroupMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreateCustomGroup
  alias Memba.Membership.Commands.EndGroupMembership
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Commands.StartGroupMembership
  alias Memba.Membership.Events.ClubMemberRemoved
  alias Memba.Membership.Events.GroupCreated
  alias Memba.Membership.Events.GroupEmailSlugAssigned
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Events.GroupMembershipEnded
  alias Memba.Membership.Events.GroupMembershipStarted
  alias Memba.Membership.GroupMembership
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups

  test "custom-group creation starts a first-class GroupMembership for its creator" do
    ids = ids()
    club = club_with_members(ids)

    command = create_custom_group_command(ids, ids.first_group_membership_id)

    assert [
             %GroupCreated{},
             %GroupEmailSlugAssigned{},
             %GroupMemberAdded{membership_id: membership_id},
             %GroupMembershipStarted{
               group_membership_id: group_membership_id,
               club_membership_id: club_membership_id,
               person_id: person_id
             }
           ] = events = Club.execute(club, command)

    assert membership_id == ids.creator_club_membership_id
    assert group_membership_id == ids.first_group_membership_id
    assert club_membership_id == ids.creator_club_membership_id
    assert person_id == ids.creator_person_id

    club = apply_events(club, events)

    assert %GroupMembership{
             group_membership_id: group_membership_id,
             club_membership_id: club_membership_id,
             status: :current
           } = club.first_class_group_memberships[ids.first_group_membership_id]

    assert group_membership_id == ids.first_group_membership_id
    assert club_membership_id == ids.creator_club_membership_id
    assert [] = Club.execute(club, command)
  end

  test "custom-group admission permits only the exact retry while current" do
    ids = ids()
    club = custom_group_with_creator(ids)
    command = add_target_command(ids, ids.second_group_membership_id)

    assert [
             %GroupMemberAdded{membership_id: target_club_membership_id},
             %GroupMembershipStarted{
               group_membership_id: group_membership_id,
               club_membership_id: started_club_membership_id
             }
           ] = events = Club.execute(club, command)

    assert target_club_membership_id == ids.target_club_membership_id
    assert started_club_membership_id == ids.target_club_membership_id
    assert group_membership_id == ids.second_group_membership_id

    club = apply_events(club, events)

    assert [] = Club.execute(club, command)

    assert {:error, :group_membership_already_current} =
             Club.execute(
               club,
               add_target_command(ids, ID.generate(:group_membership))
             )
  end

  test "start rejects a fresh identity for a current legacy relation" do
    ids = ids()

    club =
      ids
      |> custom_group_with_creator()
      |> Club.apply(%GroupMemberAdded{
        club_id: ids.club_id,
        group_id: ids.group_id,
        membership_id: ids.target_club_membership_id,
        person_id: ids.target_person_id
      })

    assert {:error, :group_membership_already_current} =
             Club.execute(club, %StartGroupMembership{
               club_id: ids.club_id,
               group_id: ids.group_id,
               group_membership_id: ids.second_group_membership_id,
               club_membership_id: ids.target_club_membership_id,
               person_id: ids.target_person_id
             })
  end

  test "start retries exactly and rejects duplicate-current or reused identities" do
    ids = ids()
    club = custom_group_with_creator(ids)

    command = %StartGroupMembership{
      club_id: ids.club_id,
      group_id: ids.group_id,
      group_membership_id: ids.second_group_membership_id,
      club_membership_id: ids.target_club_membership_id,
      person_id: ids.target_person_id
    }

    assert %GroupMembershipStarted{} = event = Club.execute(club, command)
    club = Club.apply(club, event)

    assert [] = Club.execute(club, command)

    assert {:error, :group_membership_already_current} =
             Club.execute(club, %{command | group_membership_id: ID.generate(:group_membership)})

    assert {:error, :group_membership_id_already_used} =
             Club.execute(club, %{
               command
               | club_membership_id: ids.creator_club_membership_id,
                 person_id: ids.creator_person_id
             })
  end

  test "ending names the exact GroupMembership and is idempotent" do
    ids = ids()
    club = custom_group_with_target(ids)
    command = end_target_command(ids, ids.second_group_membership_id, "remove-target-1")

    assert %GroupMembershipEnded{
             group_membership_id: group_membership_id,
             club_membership_id: club_membership_id,
             idempotency_key: "remove-target-1",
             reason: "removed_by_group_member"
           } = event = Club.execute(club, command)

    assert group_membership_id == ids.second_group_membership_id
    assert club_membership_id == ids.target_club_membership_id

    club = Club.apply(club, event)

    assert %GroupMembership{status: :ended} =
             club.first_class_group_memberships[ids.second_group_membership_id]

    assert {:error, :group_membership_already_ended} =
             Club.execute(
               club,
               add_target_command(ids, ids.second_group_membership_id)
             )

    refute Map.has_key?(
             club.current_group_membership_ids,
             {ids.group_id, ids.target_club_membership_id}
           )

    assert %{active: false} =
             club.group_memberships[{ids.group_id, ids.target_club_membership_id}]

    assert [] = Club.execute(club, command)

    conflicting_retry = %{command | reason: "club_membership_ended"}
    assert {:error, :idempotency_key_already_used} = Club.execute(club, conflicting_retry)
  end

  test "re-add gets a fresh identity and a delayed old end cannot end it" do
    ids = ids()
    club = custom_group_with_target(ids)
    old_end = end_target_command(ids, ids.second_group_membership_id, "remove-target-1")
    club = apply_events(club, Club.execute(club, old_end))
    new_group_membership_id = ID.generate(:group_membership)

    assert [%GroupMemberAdded{}, %GroupMembershipStarted{}] =
             readd_events =
             Club.execute(club, add_target_command(ids, new_group_membership_id))

    club = apply_events(club, readd_events)

    assert club.current_group_membership_ids[
             {ids.group_id, ids.target_club_membership_id}
           ] == new_group_membership_id

    assert [] = Club.execute(club, old_end)

    assert %GroupMembership{status: :current} =
             club.first_class_group_memberships[new_group_membership_id]
  end

  test "club departure ends every current custom GroupMembership atomically" do
    ids = ids()
    second_group_id = ID.generate(:group)
    third_group_membership_id = ID.generate(:group_membership)

    club =
      ids
      |> custom_group_with_target()
      |> Club.apply(%GroupCreated{
        club_id: ids.club_id,
        group_id: second_group_id,
        group_key: nil,
        name: "Trips"
      })
      |> Club.apply(%GroupMemberAdded{
        club_id: ids.club_id,
        group_id: second_group_id,
        membership_id: ids.target_club_membership_id,
        person_id: ids.target_person_id
      })
      |> Club.apply(%GroupMembershipStarted{
        club_id: ids.club_id,
        group_id: second_group_id,
        group_membership_id: third_group_membership_id,
        club_membership_id: ids.target_club_membership_id,
        person_id: ids.target_person_id
      })

    command = %RemoveClubMember{
      club_id: ids.club_id,
      membership_id: ids.target_club_membership_id,
      person_id: ids.target_person_id
    }

    events = Club.execute(club, command)
    {ending_events, departure_events} = Enum.split(events, 2)

    assert Enum.map(ending_events, & &1.group_membership_id) ==
             Enum.sort([ids.second_group_membership_id, third_group_membership_id])

    assert Enum.all?(ending_events, fn
             %GroupMembershipEnded{
               club_membership_id: club_membership_id,
               reason: "club_membership_ended"
             } ->
               club_membership_id == ids.target_club_membership_id

             _other_event ->
               false
           end)

    assert [%ClubMemberRemoved{membership_id: removed_club_membership_id} | legacy_events] =
             departure_events

    assert removed_club_membership_id == ids.target_club_membership_id
    assert length(legacy_events) == 2

    assert Enum.all?(legacy_events, fn
             %GroupMemberRemoved{membership_id: club_membership_id} ->
               club_membership_id == ids.target_club_membership_id

             _other_event ->
               false
           end)

    club = apply_events(club, events)

    refute Enum.any?(club.current_group_membership_ids, fn
             {{_group_id, club_membership_id}, _group_membership_id} ->
               club_membership_id == ids.target_club_membership_id
           end)

    for group_membership_id <- [ids.second_group_membership_id, third_group_membership_id] do
      assert %GroupMembership{status: :ended} =
               club.first_class_group_memberships[group_membership_id]
    end

    refute Map.has_key?(club.active_memberships, ids.target_club_membership_id)

    assert %{active: false} =
             club.group_memberships[{ids.group_id, ids.target_club_membership_id}]

    assert %{active: false} =
             club.group_memberships[{second_group_id, ids.target_club_membership_id}]

    assert {:error, :not_found} = Club.execute(club, command)
  end

  test "first-class lifecycle preserves system-group and club-role invariants" do
    ids = ids()
    club = club_with_members(ids)

    assert {:error, :system_group_not_allowed} =
             Club.execute(club, %StartGroupMembership{
               club_id: ids.club_id,
               group_id: SystemGroups.everyone_group_id(ids.club_id),
               group_membership_id: ids.first_group_membership_id,
               club_membership_id: ids.creator_club_membership_id,
               person_id: ids.creator_person_id
             })

    club = custom_group_with_target(ids)
    admin_role_id = Roles.membership_administrator_role_id(ids.club_id)
    role_assignments_before = club.role_assignments
    end_event = Club.execute(club, end_target_command(ids, ids.second_group_membership_id, "end"))
    club = Club.apply(club, end_event)

    assert club.role_assignments == role_assignments_before
    assert Map.has_key?(club.role_assignments, {ids.creator_club_membership_id, admin_role_id})
    assert club.active_memberships[ids.target_club_membership_id] == ids.target_person_id
  end

  defp custom_group_with_creator(ids) do
    club = club_with_members(ids)

    apply_events(
      club,
      Club.execute(club, create_custom_group_command(ids, ids.first_group_membership_id))
    )
  end

  defp custom_group_with_target(ids) do
    club = custom_group_with_creator(ids)

    apply_events(
      club,
      Club.execute(club, add_target_command(ids, ids.second_group_membership_id))
    )
  end

  defp club_with_members(ids) do
    club =
      apply_events(
        %Club{},
        Club.execute(%Club{}, %CreateClub{
          club_id: ids.club_id,
          name: "Chess Club",
          slug: "chess-club"
        })
      )

    club =
      apply_events(
        club,
        Club.execute(club, %AddClubMember{
          club_id: ids.club_id,
          membership_id: ids.creator_club_membership_id,
          person_id: ids.creator_person_id
        })
      )

    apply_events(
      club,
      Club.execute(club, %AddClubMember{
        club_id: ids.club_id,
        membership_id: ids.target_club_membership_id,
        person_id: ids.target_person_id
      })
    )
  end

  defp create_custom_group_command(ids, group_membership_id) do
    %CreateCustomGroup{
      club_id: ids.club_id,
      group_id: ids.group_id,
      group_membership_id: group_membership_id,
      actor_person_id: ids.creator_person_id,
      name: "Board"
    }
  end

  defp add_target_command(ids, group_membership_id) do
    %AddCustomGroupMember{
      club_id: ids.club_id,
      group_id: ids.group_id,
      group_membership_id: group_membership_id,
      membership_id: ids.target_club_membership_id,
      person_id: ids.target_person_id,
      actor_person_id: ids.creator_person_id
    }
  end

  defp end_target_command(ids, group_membership_id, idempotency_key) do
    %EndGroupMembership{
      club_id: ids.club_id,
      group_id: ids.group_id,
      group_membership_id: group_membership_id,
      club_membership_id: ids.target_club_membership_id,
      person_id: ids.target_person_id,
      idempotency_key: idempotency_key,
      reason: "removed_by_group_member"
    }
  end

  defp apply_events(club, events) do
    events
    |> List.wrap()
    |> Enum.reduce(club, &Club.apply(&2, &1))
  end

  defp ids do
    %{
      club_id: ID.generate(:club),
      group_id: ID.generate(:group),
      creator_club_membership_id: ID.generate(:membership),
      creator_person_id: ID.generate(:person),
      target_club_membership_id: ID.generate(:membership),
      target_person_id: ID.generate(:person),
      first_group_membership_id: ID.generate(:group_membership),
      second_group_membership_id: ID.generate(:group_membership)
    }
  end
end
