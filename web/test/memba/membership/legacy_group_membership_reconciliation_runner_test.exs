defmodule Memba.Membership.LegacyGroupMembershipReconciliationRunnerTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Event.Mapper
  alias Commanded.EventStore
  alias Memba.ID
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.Commands.EndGroupMembership
  alias Memba.Membership.Commands.RecordLegacyGroupMembershipReconciliationFence
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Commands.RemoveGroupMember
  alias Memba.Membership.Commands.StartGroupMembership
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMembershipStarted
  alias Memba.Membership.Events.LegacyGroupMembershipReconciled
  alias Memba.Membership.Events.LegacyGroupMembershipReconciliationFenceRecorded
  alias Memba.Membership.LegacyGroupMembershipReconciliation, as: Reconciliation
  alias Memba.Membership.Policies.ClearRemovedGroupMemberFollows
  alias Memba.Membership.Policies.SystemGroupMembership
  alias Memba.Membership.Projectors.Club, as: ClubProjector
  alias Memba.Membership.Projectors.FirstClassGroupMembershipV1
  alias Memba.Membership.Projectors.Group
  alias Memba.Membership.Projectors.GroupMembership
  alias Memba.Membership.Projectors.Membership
  alias Memba.Membership.Projectors.Role
  alias Memba.ProjectionBarrier

  @projectors [
    ClubProjector,
    FirstClassGroupMembershipV1,
    Group,
    GroupMembership,
    Membership,
    Role
  ]

  test "bounded apply reports incomplete work as a resumable failure" do
    ids = legacy_relations!(2)
    assert {:ok, %{fence_recorded: 2}} = record_fences(batch_size: 10)

    assert {:error, %{reason: :incomplete_batch, resumable: true, report: first}} =
             apply_reconciliation(batch_size: 1)

    assert first.attempted == 1
    assert first.reconciled == 1
    assert is_list(first.next_cursor)

    assert {:ok, second} = apply_reconciliation(batch_size: 1, after: first.next_cursor)
    assert second.attempted == 1
    assert second.reconciled == 1

    assert {:ok, retry} = apply_reconciliation(batch_size: 10)
    assert retry.already_reconciled == 2
    assert retry.reconciled == 0

    events = App |> EventStore.stream_forward(ids.club_id) |> Enum.to_list()
    assert Enum.count(events, &match?(%{data: %GroupMembershipStarted{}}, &1)) == 2
    assert Enum.count(events, &match?(%{data: %LegacyGroupMembershipReconciled{}}, &1)) == 2

    assert Enum.count(
             events,
             &match?(%{data: %LegacyGroupMembershipReconciliationFenceRecorded{}}, &1)
           ) == 1

    ProjectionBarrier.await!(@projectors)
  end

  test "dry run uses canonical decisions before and after reconciliation without writes" do
    ids = legacy_relations!(1)
    assert {:ok, %{fence_recorded: 1}} = record_fences(batch_size: 10)
    before_events = stream_events(ids.club_id)

    assert {:ok, preview} = Reconciliation.run(mode: :dry_run, batch_size: 1)
    assert preview.reconciled == 1
    assert is_binary(Jason.encode!(preview))
    assert stream_events(ids.club_id) == before_events

    assert {:ok, applied} = apply_reconciliation(batch_size: 1)
    assert applied.reconciled == 1
    after_apply = stream_events(ids.club_id)

    assert {:ok, post_preview} = Reconciliation.run(mode: :dry_run, batch_size: 1)
    assert post_preview.already_reconciled == 1
    assert stream_events(ids.club_id) == after_apply
    ProjectionBarrier.await!(@projectors)
  end

  test "dry run fails with a resumable stale diagnostic when relation changed after fence" do
    ids = legacy_relations!(1)
    [{membership_id, person_id}] = ids.memberships
    fence_version = stream_events(ids.club_id) |> List.last() |> Map.fetch!(:stream_version)

    :ok =
      App.dispatch(%RecordLegacyGroupMembershipReconciliationFence{
        club_id: ids.club_id,
        namespace: Reconciliation.namespace(),
        expected_stream_version: fence_version
      })

    ProjectionBarrier.await!(@projectors)

    append_legacy_event!(
      ids.club_id,
      %GroupMemberAdded{
        club_id: ids.club_id,
        group_id: ids.group_id,
        membership_id: membership_id,
        person_id: person_id
      }
    )

    stop_event_sourced_aggregate_instances!()

    assert {:error,
            %{
              reason: :reconciliation_source_changed,
              resumable: true,
              report: %{attempted: 0}
            }} = Reconciliation.run(mode: :dry_run, batch_size: 10)

    ProjectionBarrier.await!(@projectors)
  end

  test "dry run reports a current first-class relation" do
    ids = club_member_without_relation!()

    :ok =
      App.dispatch(%StartGroupMembership{
        club_id: ids.club_id,
        group_id: ids.group_id,
        group_membership_id: ID.generate(:group_membership),
        club_membership_id: ids.membership_id,
        person_id: ids.person_id
      })

    assert {:ok, %{fence_recorded: 1}} = record_fences(batch_size: 10)
    assert {:ok, report} = Reconciliation.run(mode: :dry_run, batch_size: 10)
    assert report.already_current == 1
    assert report.reconciled == 0
    ProjectionBarrier.await!(@projectors)
  end

  test "dry run reports an ended deterministic identity instead of recreating it" do
    ids = club_member_without_relation!()

    group_membership_id =
      Reconciliation.group_membership_id(ids.club_id, ids.group_id, ids.membership_id)

    :ok =
      App.dispatch(%StartGroupMembership{
        club_id: ids.club_id,
        group_id: ids.group_id,
        group_membership_id: group_membership_id,
        club_membership_id: ids.membership_id,
        person_id: ids.person_id
      })

    ProjectionBarrier.await!(@projectors)

    :ok =
      App.dispatch(
        %EndGroupMembership{
          club_id: ids.club_id,
          group_id: ids.group_id,
          group_membership_id: group_membership_id,
          club_membership_id: ids.membership_id,
          person_id: ids.person_id,
          idempotency_key: "ended-before-reconciliation",
          reason: "legacy_fixture"
        },
        consistency: [ClearRemovedGroupMemberFollows]
      )

    :ok =
      App.dispatch(%AddGroupMember{
        club_id: ids.club_id,
        group_id: ids.group_id,
        membership_id: ids.membership_id,
        person_id: ids.person_id
      })

    assert {:ok, %{fence_recorded: 1}} = record_fences(batch_size: 10)
    assert {:ok, report} = Reconciliation.run(mode: :dry_run, batch_size: 10)
    assert report.ended == 1
    assert report.reconciled == 0
    ProjectionBarrier.await!(@projectors)
  end

  test "fenced unreconciled explicit removal atomically materializes and ends before continuing" do
    ids = legacy_relations!(2)
    assert {:ok, _report} = record_fences(batch_size: 10)
    [{membership_id, person_id} | _rest] = Enum.sort(ids.memberships)

    :ok =
      App.dispatch(
        %RemoveGroupMember{
          club_id: ids.club_id,
          group_id: ids.group_id,
          membership_id: membership_id,
          person_id: person_id
        },
        consistency: [ClearRemovedGroupMemberFollows]
      )

    assert [
             %{data: %GroupMembershipStarted{}},
             %{data: %Memba.Membership.Events.GroupMembershipEnded{}},
             %{data: %Memba.Membership.Events.GroupMemberRemoved{}}
           ] = Enum.take(stream_events(ids.club_id), -3)

    assert {:ok, dry_run} = Reconciliation.run(mode: :dry_run, batch_size: 10)
    assert dry_run.ended == 1
    assert dry_run.reconciled == 1

    assert {:ok, applied} = apply_reconciliation(batch_size: 10)
    assert applied.ended == 1
    assert applied.reconciled == 1
    ProjectionBarrier.await!(@projectors)
  end

  test "fenced unreconciled club departure atomically materializes and ends before continuing" do
    ids = legacy_relations!(3)
    assert {:ok, _report} = record_fences(batch_size: 10)
    [{membership_id, person_id} | _rest] = Enum.drop(ids.memberships, 1)

    :ok =
      App.dispatch(
        %RemoveClubMember{
          club_id: ids.club_id,
          membership_id: membership_id,
          person_id: person_id
        },
        consistency: [SystemGroupMembership, ClearRemovedGroupMemberFollows]
      )

    events = stream_events(ids.club_id)
    started_index = Enum.find_index(events, &match?(%{data: %GroupMembershipStarted{}}, &1))

    ended_index =
      Enum.find_index(
        events,
        &match?(%{data: %Memba.Membership.Events.GroupMembershipEnded{}}, &1)
      )

    removed_index =
      Enum.find_index(events, &match?(%{data: %Memba.Membership.Events.ClubMemberRemoved{}}, &1))

    assert started_index < ended_index and ended_index < removed_index

    assert {:ok, dry_run} = Reconciliation.run(mode: :dry_run, batch_size: 10)
    assert dry_run.ended == 1
    assert dry_run.reconciled == 2

    assert {:ok, applied} = apply_reconciliation(batch_size: 10)
    assert applied.ended == 1
    assert applied.reconciled == 2
    ProjectionBarrier.await!(@projectors)
  end

  test "post-fence first-class end is terminal and later items continue in dry-run and apply" do
    ids = legacy_relations!(2)
    assert {:ok, _report} = record_fences(batch_size: 10)
    assert {:ok, %{reconciled: 2}} = apply_reconciliation(batch_size: 10)

    [{membership_id, person_id} | _rest] = Enum.sort(ids.memberships)

    group_membership_id =
      Reconciliation.group_membership_id(ids.club_id, ids.group_id, membership_id)

    :ok =
      App.dispatch(
        %EndGroupMembership{
          club_id: ids.club_id,
          group_id: ids.group_id,
          group_membership_id: group_membership_id,
          club_membership_id: membership_id,
          person_id: person_id,
          idempotency_key: "post-fence-end",
          reason: "removed_after_fence"
        },
        consistency: [ClearRemovedGroupMemberFollows]
      )

    assert {:ok, dry_run} = Reconciliation.run(mode: :dry_run, batch_size: 10)
    assert dry_run.ended == 1
    assert dry_run.already_reconciled == 1

    assert {:ok, applied} = apply_reconciliation(batch_size: 10)
    assert applied.ended == 1
    assert applied.already_reconciled == 1
    ProjectionBarrier.await!(@projectors)
  end

  test "post-fence club departure is terminal and later items continue in dry-run and apply" do
    ids = legacy_relations!(3)
    assert {:ok, _report} = record_fences(batch_size: 10)
    assert {:ok, %{reconciled: 3}} = apply_reconciliation(batch_size: 10)

    [{membership_id, person_id} | _rest] = Enum.drop(ids.memberships, 1)

    :ok =
      App.dispatch(
        %RemoveClubMember{
          club_id: ids.club_id,
          membership_id: membership_id,
          person_id: person_id
        },
        consistency: [SystemGroupMembership, ClearRemovedGroupMemberFollows]
      )

    assert {:ok, dry_run} = Reconciliation.run(mode: :dry_run, batch_size: 10)
    assert dry_run.ended == 1
    assert dry_run.already_reconciled == 2

    assert {:ok, applied} = apply_reconciliation(batch_size: 10)
    assert applied.ended == 1
    assert applied.already_reconciled == 2
    ProjectionBarrier.await!(@projectors)
  end

  test "dry run reports deterministic identity conflicts as operational failures" do
    club_id = ID.generate(:club)
    membership_id = ID.generate(:membership)
    person_id = ID.generate(:person)
    legacy_group_id = "grp_00000000-0000-0000-0000-000000000001"
    other_group_id = "grp_00000000-0000-0000-0000-000000000002"

    :ok = App.dispatch(%CreateClub{club_id: club_id, name: "Club", slug: "club"})

    for {group_id, slug} <- [{legacy_group_id, "legacy"}, {other_group_id, "other"}] do
      :ok =
        App.dispatch(%CreateGroup{
          club_id: club_id,
          group_id: group_id,
          email_slug: slug,
          group_key: nil,
          name: String.capitalize(slug)
        })
    end

    :ok =
      App.dispatch(
        %AddClubMember{
          club_id: club_id,
          membership_id: membership_id,
          person_id: person_id
        },
        consistency: [SystemGroupMembership]
      )

    conflicting_id = Reconciliation.group_membership_id(club_id, legacy_group_id, membership_id)

    :ok =
      App.dispatch(%StartGroupMembership{
        club_id: club_id,
        group_id: other_group_id,
        group_membership_id: conflicting_id,
        club_membership_id: membership_id,
        person_id: person_id
      })

    :ok =
      App.dispatch(%AddGroupMember{
        club_id: club_id,
        group_id: legacy_group_id,
        membership_id: membership_id,
        person_id: person_id
      })

    assert {:ok, _report} = record_fences(batch_size: 10)

    assert {:error,
            %{reason: :reconciliation_identity_conflict, resumable: true, report: %{attempted: 0}}} =
             Reconciliation.run(mode: :dry_run, batch_size: 10)

    ProjectionBarrier.await!(@projectors)
  end

  test "invalid operational configuration fails closed" do
    assert {:error, :cutover_acknowledgement_required} =
             Reconciliation.run(mode: :apply, batch_size: 1)

    assert {:error, :invalid_batch_size} = Reconciliation.run(batch_size: 0)
    assert {:error, :invalid_batch_size} = Reconciliation.run(batch_size: 501)
    assert {:error, :invalid_cursor} = Reconciliation.run(after: ["bad"])
    assert {:error, :invalid_cursor} = Reconciliation.run(after: ["bad", "bad", "bad"])
    assert {:error, :invalid_club_ids} = Reconciliation.run(club_ids: [])
    assert {:error, :invalid_club_ids} = Reconciliation.run(club_ids: ["bad"])
    assert {:error, :invalid_namespace} = Reconciliation.run(namespace: "")
  end

  defp record_fences(opts) do
    Reconciliation.run(
      Keyword.merge(
        [
          mode: :record_fences,
          cutover_acknowledgement: Reconciliation.cutover_acknowledgement()
        ],
        opts
      )
    )
  end

  defp apply_reconciliation(opts) do
    Reconciliation.run(
      Keyword.merge(
        [
          mode: :apply,
          cutover_acknowledgement: Reconciliation.cutover_acknowledgement()
        ],
        opts
      )
    )
  end

  defp stream_events(club_id), do: App |> EventStore.stream_forward(club_id) |> Enum.to_list()

  defp append_legacy_event!(club_id, event) do
    expected_version = stream_events(club_id) |> List.last() |> Map.fetch!(:stream_version)

    assert :ok =
             EventStore.append_to_stream(App, club_id, expected_version, [
               Mapper.map_to_event_data(event)
             ])
  end

  defp club_member_without_relation! do
    ids = club_and_group!()
    membership_id = ID.generate(:membership)
    person_id = ID.generate(:person)

    :ok =
      App.dispatch(
        %AddClubMember{
          club_id: ids.club_id,
          membership_id: membership_id,
          person_id: person_id
        },
        consistency: [SystemGroupMembership]
      )

    Map.merge(ids, %{membership_id: membership_id, person_id: person_id})
  end

  defp club_and_group! do
    club_id = ID.generate(:club)
    group_id = ID.generate(:group)
    :ok = App.dispatch(%CreateClub{club_id: club_id, name: "Club", slug: "club"})

    :ok =
      App.dispatch(%CreateGroup{
        club_id: club_id,
        group_id: group_id,
        email_slug: "board",
        group_key: nil,
        name: "Board"
      })

    %{club_id: club_id, group_id: group_id}
  end

  defp legacy_relations!(count) do
    ids = club_and_group!()

    memberships =
      for _ <- 1..count do
        membership_id = ID.generate(:membership)
        person_id = ID.generate(:person)

        :ok =
          App.dispatch(
            %AddClubMember{
              club_id: ids.club_id,
              membership_id: membership_id,
              person_id: person_id
            },
            consistency: [SystemGroupMembership]
          )

        :ok =
          App.dispatch(%AddGroupMember{
            club_id: ids.club_id,
            group_id: ids.group_id,
            membership_id: membership_id,
            person_id: person_id
          })

        {membership_id, person_id}
      end

    ProjectionBarrier.await!(@projectors)
    Map.put(ids, :memberships, memberships)
  end
end
