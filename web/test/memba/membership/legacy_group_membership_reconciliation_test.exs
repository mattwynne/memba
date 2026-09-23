defmodule Memba.Membership.LegacyGroupMembershipReconciliationTest do
  use ExUnit.Case, async: true

  alias Memba.ID
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.ReconcileLegacyGroupMembership
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Commands.RemoveGroupMember
  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.ClubMemberRemoved
  alias Memba.Membership.Events.GroupCreated
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Events.GroupMembershipEnded
  alias Memba.Membership.Events.GroupMembershipStarted
  alias Memba.Membership.Events.LegacyGroupMembershipReconciled
  alias Memba.Membership.Events.LegacyGroupMembershipReconciliationFenceRecorded
  alias Memba.Membership.LegacyGroupMembershipReconciliation, as: Reconciliation
  alias Memba.Membership.SystemGroups

  test "active legacy custom relation is reconciled with deterministic identity and no dates" do
    {club, ids} = active_legacy_relation()
    command = command(club, ids)

    assert command.group_membership_id ==
             Reconciliation.group_membership_id(ids.club_id, ids.group_id, ids.membership_id)

    assert [
             %GroupMembershipStarted{
               group_membership_id: group_membership_id,
               club_membership_id: club_membership_id
             } = started,
             %LegacyGroupMembershipReconciled{
               group_membership_id: reconciled_group_membership_id
             }
           ] = Club.execute(club, command)

    assert reconciled_group_membership_id == group_membership_id
    assert club_membership_id == ids.membership_id
    refute Map.has_key?(Map.from_struct(started), :started_at)
  end

  test "inactive relation and system groups are not reconciled" do
    {club, ids} = active_legacy_relation()

    inactive =
      Club.apply(club, %GroupMemberRemoved{
        club_id: ids.club_id,
        group_id: ids.group_id,
        membership_id: ids.membership_id,
        person_id: ids.person_id
      })

    assert {:error, :reconciliation_source_changed} = Club.execute(inactive, command(club, ids))

    {system_club, system_ids} = active_legacy_relation(group_key: "everyone")

    assert {:error, :system_group_not_allowed} =
             Club.execute(system_club, command(system_club, system_ids))
  end

  test "exact retry and aggregate replay emit no duplicate lifecycle" do
    {club, ids} = active_legacy_relation()
    command = command(club, ids)
    events = Club.execute(club, command)
    reconciled = Enum.reduce(events, club, &Club.apply(&2, &1))

    assert [] = Club.execute(reconciled, command)

    replayed =
      active_legacy_events(ids)
      |> Kernel.++(events)
      |> Enum.reduce(%Club{}, &Club.apply(&2, &1))

    assert [] = Club.execute(replayed, command)
    assert replayed.first_class_group_memberships == reconciled.first_class_group_memberships
  end

  test "restart preserves club membership and roles while retrying the fenced relation" do
    {club, ids} = active_legacy_relation()
    roles = club.roles
    active_memberships = club.active_memberships
    events = Club.execute(club, command(club, ids))
    restarted = Enum.reduce(events, club, &Club.apply(&2, &1))

    assert [] = Club.execute(restarted, command(restarted, ids))
    assert restarted.active_memberships == active_memberships
    assert restarted.roles == roles
  end

  test "reconciled membership is ended by legacy removal and replayed retry is exact" do
    {club, ids} = active_legacy_relation()
    reconciliation_events = Club.execute(club, command(club, ids))
    reconciled = Enum.reduce(reconciliation_events, club, &Club.apply(&2, &1))

    remove = %RemoveGroupMember{
      club_id: ids.club_id,
      group_id: ids.group_id,
      membership_id: ids.membership_id,
      person_id: ids.person_id
    }

    assert [
             %GroupMembershipEnded{group_membership_id: group_membership_id},
             %GroupMemberRemoved{}
           ] = removal_events = Club.execute(reconciled, remove)

    assert group_membership_id == command(club, ids).group_membership_id
    removed = Enum.reduce(removal_events, reconciled, &Club.apply(&2, &1))
    assert [] = Club.execute(removed, remove)

    replayed =
      (active_legacy_events(ids) ++ reconciliation_events ++ removal_events)
      |> Enum.reduce(%Club{}, &Club.apply(&2, &1))

    assert [] = Club.execute(replayed, remove)
    assert replayed.first_class_group_memberships[group_membership_id].status == :ended
  end

  test "club departure ends replayed first-class membership after legacy-only removal" do
    {club, ids} = active_legacy_relation()
    reconciliation_events = Club.execute(club, command(club, ids))
    reconciled = Enum.reduce(reconciliation_events, club, &Club.apply(&2, &1))

    legacy_removed = Club.apply(reconciled, removed_event(ids))
    other_membership_id = ID.generate(:membership)
    other_person_id = ID.generate(:person)

    replayed =
      Club.apply(legacy_removed, %ClubMemberAdded{
        club_id: ids.club_id,
        membership_id: other_membership_id,
        person_id: other_person_id
      })

    remove_club_member = %RemoveClubMember{
      club_id: ids.club_id,
      membership_id: ids.membership_id,
      person_id: ids.person_id
    }

    assert [
             %GroupMembershipEnded{group_membership_id: group_membership_id},
             %ClubMemberRemoved{}
           ] = departure_events = Club.execute(replayed, remove_club_member)

    departed = Enum.reduce(departure_events, replayed, &Club.apply(&2, &1))
    refute Map.has_key?(departed.current_group_membership_ids, {ids.group_id, ids.membership_id})
    assert departed.first_class_group_memberships[group_membership_id].status == :ended
  end

  test "remove or remove-add after enumeration is rejected at the old fence" do
    {club, ids} = active_legacy_relation()
    stale_command = command(club, ids)

    removed = Club.apply(club, removed_event(ids))
    assert {:error, :reconciliation_source_changed} = Club.execute(removed, stale_command)

    readded = Club.apply(removed, added_event(ids))
    assert {:error, :reconciliation_source_changed} = Club.execute(readded, stale_command)

    assert {:error, :reconciliation_source_changed} =
             Club.execute(readded, command(readded, ids))
  end

  test "unrelated post-fence source change does not move the durable fence" do
    {club, ids} = active_legacy_relation()
    stale_command = command(club, ids)

    changed =
      Club.apply(club, %GroupCreated{
        club_id: ids.club_id,
        group_id: ID.generate(:group),
        group_key: nil,
        name: "Another"
      })

    assert [%GroupMembershipStarted{}, %LegacyGroupMembershipReconciled{}] =
             Club.execute(changed, stale_command)
  end

  test "a command naming a different fence is rejected" do
    {club, ids} = active_legacy_relation()
    command = command(club, ids)

    assert {:error, :reconciliation_stale_fence} =
             Club.execute(club, %{
               command
               | fence_stream_version: command.fence_stream_version + 1
             })
  end

  test "ended deterministic identity with different data is a conflict" do
    {club, ids} = active_legacy_relation()
    command = command(club, ids)
    other_group_id = ID.generate(:group)

    collided =
      club
      |> Club.apply(%GroupMembershipStarted{
        club_id: ids.club_id,
        group_id: other_group_id,
        group_membership_id: command.group_membership_id,
        club_membership_id: ids.membership_id,
        person_id: ids.person_id
      })
      |> Club.apply(%GroupMembershipEnded{
        club_id: ids.club_id,
        group_id: other_group_id,
        group_membership_id: command.group_membership_id,
        club_membership_id: ids.membership_id,
        person_id: ids.person_id,
        idempotency_key: "collision-ended",
        reason: "collision_fixture"
      })

    assert {:error, :reconciliation_identity_conflict} = Club.execute(collided, command)
  end

  test "conflicting deterministic identity or reconciliation data fails loudly" do
    {club, ids} = active_legacy_relation()
    command = command(club, ids)

    assert {:error, :non_deterministic_group_membership_id} =
             Club.execute(club, %{command | group_membership_id: ID.generate(:group_membership)})

    events = Club.execute(club, command)
    reconciled = Enum.reduce(events, club, &Club.apply(&2, &1))

    assert {:error, :reconciliation_identity_conflict} =
             Club.execute(reconciled, %{
               command
               | source_stream_version: command.source_stream_version + 1
             })
  end

  defp active_legacy_relation(opts \\ []) do
    club_id = ID.generate(:club)

    group_id =
      case Keyword.get(opts, :group_key) do
        "everyone" -> SystemGroups.everyone_group_id(club_id)
        _ -> ID.generate(:group)
      end

    ids = %{
      club_id: club_id,
      group_id: group_id,
      membership_id: ID.generate(:membership),
      person_id: ID.generate(:person)
    }

    club = Enum.reduce(active_legacy_events(ids, opts), %Club{}, &Club.apply(&2, &1))
    {club, ids}
  end

  defp active_legacy_events(ids, opts \\ []) do
    [
      %ClubCreated{club_id: ids.club_id, name: "Club", slug: "club"},
      %GroupCreated{
        club_id: ids.club_id,
        group_id: ids.group_id,
        group_key: Keyword.get(opts, :group_key),
        name: "Board"
      },
      %ClubMemberAdded{
        club_id: ids.club_id,
        membership_id: ids.membership_id,
        person_id: ids.person_id
      },
      added_event(ids),
      %LegacyGroupMembershipReconciliationFenceRecorded{
        club_id: ids.club_id,
        namespace: Reconciliation.namespace(),
        source_stream_version: 4
      }
    ]
  end

  defp added_event(ids) do
    %GroupMemberAdded{
      club_id: ids.club_id,
      group_id: ids.group_id,
      membership_id: ids.membership_id,
      person_id: ids.person_id
    }
  end

  defp removed_event(ids) do
    %GroupMemberRemoved{
      club_id: ids.club_id,
      group_id: ids.group_id,
      membership_id: ids.membership_id,
      person_id: ids.person_id
    }
  end

  defp command(club, ids) do
    %ReconcileLegacyGroupMembership{
      club_id: ids.club_id,
      group_id: ids.group_id,
      group_membership_id:
        Reconciliation.group_membership_id(ids.club_id, ids.group_id, ids.membership_id),
      club_membership_id: ids.membership_id,
      person_id: ids.person_id,
      namespace: Reconciliation.namespace(),
      fence_stream_version:
        club.legacy_group_membership_reconciliation_fence.source_stream_version,
      source_stream_version:
        club.legacy_group_memberships[{ids.group_id, ids.membership_id}].source_stream_version
    }
  end
end
