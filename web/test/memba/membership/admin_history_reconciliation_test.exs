defmodule Memba.Membership.AdminHistoryReconciliationTest do
  use Memba.EventSourcedCase, async: false

  import Ecto.Query
  import ExUnit.CaptureIO

  alias Commanded.Event.Mapper
  alias Commanded.EventStore
  alias Memba.Membership.AdminHistoryReconciliation
  alias Memba.Membership.App
  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Events.ClubRoleAssignedToMember
  alias Memba.Membership.Events.ClubRoleDefined
  alias Memba.Membership.Events.ClubRolePermissionGranted
  alias Memba.Membership.Events.MemberAdded
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.MemberPermission, as: MemberPermissionProjection
  alias Memba.Membership.Projections.Role, as: RoleProjection
  alias Memba.Membership.Projections.RoleAssignment, as: RoleAssignmentProjection
  alias Memba.Membership.Projections.RolePermission, as: RolePermissionProjection
  alias Memba.Membership.Projectors.Club, as: ClubProjector
  alias Memba.Membership.Projectors.Membership, as: MembershipProjector
  alias Memba.Membership.Projectors.Role, as: RoleProjector
  alias Memba.Membership.Roles
  alias Memba.ProjectionBarrier
  alias Memba.Release

  describe "plan/1" do
    test "dry-run writes nothing and reports three missing canonical facts" do
      candidate = legacy_admin_candidate!()
      before_events = recorded_events(candidate.club_id)

      report = AdminHistoryReconciliation.plan()

      assert report.mode == :dry_run
      assert report.totals.candidates == 1
      assert report.totals.repairable == 1
      assert report.totals.events_planned == 3

      assert [planned] = candidates(report)
      assert planned.status == :repairable

      assert planned.missing_facts == [
               "club_role_defined",
               "club_role_permission_granted",
               "club_role_assigned_to_member"
             ]

      assert planned.current_grant_count == 1
      assert planned.expected_grant_count == 1
      assert recorded_events(candidate.club_id) == before_events
    end

    test "partial aggregate histories report only facts still missing" do
      role_defined = legacy_admin_candidate!(history_facts: [:role_defined])

      permission_granted =
        legacy_admin_candidate!(history_facts: [:role_defined, :permission_granted])

      report = AdminHistoryReconciliation.plan()

      planned_by_club = Map.new(candidates(report), &{&1.club_id, &1.missing_facts})

      assert planned_by_club[role_defined.club_id] == [
               "club_role_permission_granted",
               "club_role_assigned_to_member"
             ]

      assert planned_by_club[permission_granted.club_id] == ["club_role_assigned_to_member"]
    end

    test "canonical projections with historic aggregate role facts are already reconciled" do
      candidate =
        legacy_admin_candidate!(
          history_facts: [:historic_role_defined, :permission_granted, :role_assigned]
        )

      canonicalize_admin_role_projection!(candidate.club_id, candidate.role_id)
      before_events = recorded_events(candidate.club_id)

      report = AdminHistoryReconciliation.plan(club_ids: [candidate.club_id])

      assert report.totals.already_reconciled == 1
      assert report.totals.manual_review == 0
      assert report.totals.events_planned == 0
      assert [planned] = candidates(report)
      assert planned.status == :already_reconciled
      assert planned.missing_facts == []
      assert recorded_events(candidate.club_id) == before_events
    end

    test "two admins in one club are planned sequentially" do
      first = legacy_admin_candidate!()
      second = add_projected_admin_candidate!(first.club_id)

      report = AdminHistoryReconciliation.plan(club_ids: [first.club_id])

      assert Enum.map(candidates(report), & &1.membership_id) ==
               Enum.sort([first.membership_id, second.membership_id])

      assert Enum.map(candidates(report), & &1.events_planned) == [3, 1]
      assert report.totals.events_planned == 4
    end

    test "multiple distinct permission-granting roles preserve grant count 2" do
      candidate = legacy_admin_candidate!(grant_count: 2)

      insert_custom_permission_grant!(
        candidate.club_id,
        candidate.membership_id,
        candidate.person_id
      )

      report = AdminHistoryReconciliation.plan(club_ids: [candidate.club_id])

      assert [planned] = candidates(report)
      assert planned.status == :repairable
      assert planned.current_grant_count == 2
      assert planned.expected_grant_count == 2
    end

    test "contradictory projections and wrong flattened counts require manual review" do
      wrong_role = legacy_admin_candidate!(role_id: Memba.ID.generate(:role))
      wrong_count = legacy_admin_candidate!(grant_count: 2)

      report = AdminHistoryReconciliation.plan()
      planned_by_club = Map.new(candidates(report), &{&1.club_id, &1})

      assert planned_by_club[wrong_role.club_id].status == :manual_review
      assert planned_by_club[wrong_role.club_id].reason == :admin_role_id_mismatch
      assert planned_by_club[wrong_role.club_id].events_planned == 0

      assert planned_by_club[wrong_count.club_id].status == :manual_review
      assert planned_by_club[wrong_count.club_id].reason == :flattened_grant_count_mismatch
      assert planned_by_club[wrong_count.club_id].events_planned == 0
    end

    test "explicit club allow-list scopes candidates" do
      included = legacy_admin_candidate!()
      excluded = legacy_admin_candidate!()

      report = AdminHistoryReconciliation.plan(club_ids: [included.club_id])

      assert Enum.map(candidates(report), & &1.club_id) == [included.club_id]
      refute Enum.any?(candidates(report), &(&1.club_id == excluded.club_id))
    end

    test "structured report omits names and emails" do
      candidate = legacy_admin_candidate!()

      encoded =
        candidate.club_id
        |> then(&AdminHistoryReconciliation.plan(club_ids: [&1]))
        |> Jason.encode!()

      refute encoded =~ "Ada Lovelace"
      refute encoded =~ "ada@example.test"
      assert encoded =~ candidate.membership_id
    end

    test "waits for Membership and Role projectors before building the plan" do
      parent = self()

      AdminHistoryReconciliation.plan(
        projection_barrier: fn projectors, opts ->
          send(parent, {:projection_barrier_awaited, projectors, opts})
        end
      )

      assert_received {:projection_barrier_awaited, [MembershipProjector, RoleProjector],
                       [timeout: 60_000]}
    end
  end

  describe "run/1 apply" do
    test "apply appends canonical facts with metadata and leaves grant_count at 1" do
      candidate = legacy_admin_candidate!()

      assert {:ok, report} = apply_reconciliation(candidate.club_id)

      assert report.mode == :apply
      assert report.totals.events_planned == 3
      assert report.totals.events_appended == 3
      assert report.totals.already_reconciled == 1

      assert [%ClubRoleDefined{}, %ClubRolePermissionGranted{}, %ClubRoleAssignedToMember{}] =
               appended_event_data(candidate.club_id, 2)

      assert %MemberPermissionProjection{grant_count: 1} =
               Repo.get_by(MemberPermissionProjection,
                 club_id: candidate.club_id,
                 membership_id: candidate.membership_id,
                 person_id: candidate.person_id,
                 permission: Permissions.club_manage_members()
               )

      appended_metadata = appended_event_metadata(candidate.club_id, 2)

      assert Enum.all?(appended_metadata, fn metadata ->
               metadata["operation_id"] == "op-1" and
                 metadata["approval_reference"] == "approval-1" and
                 metadata["repair_kind"] == "legacy_admin_history_reconciliation"
             end)
    end

    test "already-reconciled retry appends no new events" do
      candidate = legacy_admin_candidate!()
      assert {:ok, _report} = apply_reconciliation(candidate.club_id)
      after_first_apply = length(recorded_events(candidate.club_id))

      assert {:ok, retry_report} = apply_reconciliation(candidate.club_id, operation_id: "op-2")

      assert retry_report.totals.events_planned == 0
      assert retry_report.totals.events_appended == 0
      assert [planned] = candidates(retry_report)
      assert planned.status == :already_reconciled
      assert length(recorded_events(candidate.club_id)) == after_first_apply
    end

    test "apply treats canonical projections with historic aggregate role facts as already reconciled" do
      candidate =
        legacy_admin_candidate!(
          history_facts: [:historic_role_defined, :permission_granted, :role_assigned]
        )

      canonicalize_admin_role_projection!(candidate.club_id, candidate.role_id)
      before_count = length(recorded_events(candidate.club_id))

      assert {:ok, report} = apply_reconciliation(candidate.club_id)

      assert report.totals.already_reconciled == 1
      assert report.totals.manual_review == 0
      assert report.totals.events_planned == 0
      assert report.totals.events_appended == 0
      assert [planned] = candidates(report)
      assert planned.status == :already_reconciled
      assert length(recorded_events(candidate.club_id)) == before_count
    end

    test "post-apply verification reports initial target that disappears from post plan" do
      candidate = legacy_admin_candidate!()

      assert {:error,
              %{
                error: :post_apply_verification_failed,
                report: report
              }} =
               apply_reconciliation(candidate.club_id,
                 post_apply_plan: fn _opts -> %{clubs: []} end
               )

      assert report.mode == :apply
      assert report.totals.candidates == 1
      assert report.totals.post_apply_missing_candidate == 1
      assert report.totals.events_planned == 3
      assert report.totals.events_appended == 3

      assert [missing] = candidates(report)
      assert missing.club_id == candidate.club_id
      assert missing.membership_id == candidate.membership_id
      assert missing.person_id == candidate.person_id
      assert missing.status == :post_apply_missing_candidate
      assert missing.reason == :post_apply_missing_candidate
      assert missing.events_planned == 3
      assert missing.events_appended == 3
      assert Jason.encode!(report)
    end

    test "two admins in one club append one role definition, one permission, and two assignments" do
      first = legacy_admin_candidate!()
      _second = add_projected_admin_candidate!(first.club_id)

      assert {:ok, report} = apply_reconciliation(first.club_id)

      assert report.totals.events_planned == 4
      assert report.totals.events_appended == 4

      appended = appended_event_data(first.club_id, 3)
      assert Enum.count(appended, &match?(%ClubRoleDefined{}, &1)) == 1
      assert Enum.count(appended, &match?(%ClubRolePermissionGranted{}, &1)) == 1
      assert Enum.count(appended, &match?(%ClubRoleAssignedToMember{}, &1)) == 2
    end

    test "multiple distinct permission-granting roles keep flattened grant_count 2 after apply" do
      candidate = legacy_admin_candidate!(grant_count: 2)

      insert_custom_permission_grant!(
        candidate.club_id,
        candidate.membership_id,
        candidate.person_id
      )

      assert {:ok, _report} = apply_reconciliation(candidate.club_id)

      assert %MemberPermissionProjection{grant_count: 2} =
               Repo.get_by(MemberPermissionProjection,
                 club_id: candidate.club_id,
                 membership_id: candidate.membership_id,
                 person_id: candidate.person_id,
                 permission: Permissions.club_manage_members()
               )
    end

    test "apply safeguards prevent writes before dispatch" do
      candidate = legacy_admin_candidate!()
      before_count = length(recorded_events(candidate.club_id))

      assert {:error, %{error: :apply_safeguards_failed, reasons: reasons}} =
               AdminHistoryReconciliation.run(mode: :apply, club_ids: [candidate.club_id])

      assert :operation_id_required in reasons
      assert :approval_reference_required in reasons
      assert :acknowledgement_required in reasons
      assert length(recorded_events(candidate.club_id)) == before_count
    end

    test "mixed repairable and manual-review scope appends nothing and reports preflight error" do
      repairable = legacy_admin_candidate!()
      manual_review = legacy_admin_candidate!(role_id: Memba.ID.generate(:role))

      before_repairable_count = length(recorded_events(repairable.club_id))
      before_manual_review_count = length(recorded_events(manual_review.club_id))

      assert {:error,
              %{
                error: :apply_preflight_failed,
                reasons: reasons,
                plan: %{totals: %{repairable: 1, manual_review: 1}}
              } = error} = apply_reconciliation([repairable.club_id, manual_review.club_id])

      assert %{reason: :manual_review_candidates_present, candidates: [candidate]} =
               Enum.find(reasons, &(&1.reason == :manual_review_candidates_present))

      assert candidate.club_id == manual_review.club_id
      assert candidate.reason == :admin_role_id_mismatch
      assert Jason.encode!(error)

      assert length(recorded_events(repairable.club_id)) == before_repairable_count
      assert length(recorded_events(manual_review.club_id)) == before_manual_review_count
    end

    test "explicitly scoped club with no qualifying projected Admin evidence appends nothing" do
      club_id = Memba.ID.generate(:club)
      membership_id = Memba.ID.generate(:membership)
      person_id = Memba.ID.generate(:person)

      append_legacy_membership_history!(club_id, membership_id, person_id, [])
      before_count = length(recorded_events(club_id))

      assert {:error,
              %{
                error: :apply_preflight_failed,
                reasons: reasons,
                plan: %{totals: %{candidates: 0}}
              } = error} = apply_reconciliation(club_id)

      assert %{reason: :scoped_clubs_missing_candidates, club_ids: [^club_id]} =
               Enum.find(reasons, &(&1.reason == :scoped_clubs_missing_candidates))

      assert %{reason: :no_candidates_planned} =
               Enum.find(reasons, &(&1.reason == :no_candidates_planned))

      assert Jason.encode!(error)
      assert length(recorded_events(club_id)) == before_count
    end

    test "zero-candidate apply errors instead of succeeding vacuously" do
      club_id = Memba.ID.generate(:club)

      assert recorded_events(club_id) == []

      assert {:error,
              %{
                error: :apply_preflight_failed,
                reasons: reasons,
                plan: %{totals: %{candidates: 0}}
              }} = apply_reconciliation(club_id)

      assert %{reason: :no_candidates_planned} =
               Enum.find(reasons, &(&1.reason == :no_candidates_planned))

      assert %{reason: :scoped_clubs_missing_candidates, club_ids: [^club_id]} =
               Enum.find(reasons, &(&1.reason == :scoped_clubs_missing_candidates))

      assert recorded_events(club_id) == []
    end
  end

  describe "operator entry points" do
    test "mix task starts the app path and prints JSON dry-run output" do
      candidate = legacy_admin_candidate!()
      Mix.Task.reenable("memba.admin_history")

      output =
        capture_io(fn ->
          Mix.Tasks.Memba.AdminHistory.run(["--dry-run", "--club-id", candidate.club_id])
        end)

      assert %{"mode" => "dry_run", "totals" => %{"candidates" => 1}} = Jason.decode!(output)
    end

    test "release wrapper reads MEMBA_ADMIN_HISTORY variables, defaults dry-run, and prints JSON" do
      candidate = legacy_admin_candidate!()
      original_overrides = Application.get_env(:memba, :release_step_overrides)

      try do
        Application.put_env(:memba, :release_step_overrides,
          load_app: fn -> :ok end,
          ensure_release_services_started: fn -> :ok end
        )

        with_env(%{"MEMBA_ADMIN_HISTORY_CLUB_IDS" => candidate.club_id}, fn ->
          output = capture_io(fn -> Release.reconcile_legacy_admin_history!() end)
          assert %{"mode" => "dry_run", "totals" => %{"candidates" => 1}} = Jason.decode!(output)
        end)
      after
        case original_overrides do
          nil -> Application.delete_env(:memba, :release_step_overrides)
          overrides -> Application.put_env(:memba, :release_step_overrides, overrides)
        end
      end
    end
  end

  defp apply_reconciliation(club_id_or_ids, opts \\ []) do
    club_ids = List.wrap(club_id_or_ids)

    AdminHistoryReconciliation.run(
      Keyword.merge(
        [
          mode: :apply,
          club_ids: club_ids,
          operation_id: Keyword.get(opts, :operation_id, "op-1"),
          approval_reference: "approval-1",
          acknowledgement: AdminHistoryReconciliation.acknowledgement()
        ],
        opts
      )
    )
  end

  defp legacy_admin_candidate!(opts \\ []) do
    club_id = Keyword.get_lazy(opts, :club_id, fn -> Memba.ID.generate(:club) end)

    membership_id =
      Keyword.get_lazy(opts, :membership_id, fn -> Memba.ID.generate(:membership) end)

    person_id = Keyword.get_lazy(opts, :person_id, fn -> Memba.ID.generate(:person) end)

    append_legacy_membership_history!(
      club_id,
      membership_id,
      person_id,
      Keyword.get(opts, :history_facts, [])
    )

    role_id = Keyword.get(opts, :role_id, Roles.membership_administrator_role_id(club_id))

    insert_admin_projection_rows!(%{
      club_id: club_id,
      membership_id: membership_id,
      person_id: person_id,
      role_id: role_id,
      grant_count: Keyword.get(opts, :grant_count, 1)
    })
  end

  defp add_projected_admin_candidate!(club_id) do
    membership_id = Memba.ID.generate(:membership)
    person_id = Memba.ID.generate(:person)

    append_legacy_member!(club_id, membership_id, person_id)

    insert_admin_projection_rows!(%{
      club_id: club_id,
      membership_id: membership_id,
      person_id: person_id,
      role_id: Roles.membership_administrator_role_id(club_id),
      grant_count: 1
    })
  end

  defp append_legacy_membership_history!(club_id, membership_id, person_id, history_facts) do
    role_id = Roles.membership_administrator_role_id(club_id)

    events =
      [
        %ClubCreated{
          club_id: club_id,
          name: "Kootenay Mountaineering Club",
          slug: club_slug(club_id)
        },
        %MemberAdded{club_id: club_id, membership_id: membership_id, person_id: person_id}
      ] ++ canonical_history_events(club_id, membership_id, person_id, role_id, history_facts)

    append_events!(club_id, events, 0)
    ProjectionBarrier.await!([ClubProjector, MembershipProjector, RoleProjector], timeout: 1_000)
  end

  defp append_legacy_member!(club_id, membership_id, person_id) do
    expected_version = length(recorded_events(club_id))

    append_events!(
      club_id,
      [%MemberAdded{club_id: club_id, membership_id: membership_id, person_id: person_id}],
      expected_version
    )

    ProjectionBarrier.await!([MembershipProjector], timeout: 1_000)
  end

  defp club_slug(club_id) do
    suffix =
      club_id
      |> String.split("_", parts: 2)
      |> List.last()
      |> String.replace("-", "")
      |> String.slice(0, 8)

    "kmc-#{suffix}"
  end

  defp canonical_history_events(club_id, membership_id, person_id, role_id, history_facts) do
    Enum.flat_map(history_facts, fn
      :role_defined ->
        [
          %ClubRoleDefined{
            club_id: club_id,
            role_id: role_id,
            role_key: Roles.membership_administrator_key(),
            name: Roles.membership_administrator_name()
          }
        ]

      :historic_role_defined ->
        [
          %ClubRoleDefined{
            club_id: club_id,
            role_id: role_id,
            role_key: Roles.historic_membership_administrator_key(),
            name: Roles.historic_membership_administrator_name()
          }
        ]

      :permission_granted ->
        [
          %ClubRolePermissionGranted{
            club_id: club_id,
            role_id: role_id,
            permission: Permissions.club_manage_members()
          }
        ]

      :role_assigned ->
        [
          %ClubRoleAssignedToMember{
            club_id: club_id,
            membership_id: membership_id,
            person_id: person_id,
            role_id: role_id,
            assigned_by_person_id: nil,
            assignment_source: "test"
          }
        ]
    end)
  end

  defp append_events!(stream_id, events, expected_version) do
    event_data = Enum.map(events, &Mapper.map_to_event_data/1)
    assert :ok = EventStore.append_to_stream(App, stream_id, expected_version, event_data)
  end

  defp insert_admin_projection_rows!(attrs) do
    insert_role_projection!(
      attrs.club_id,
      attrs.role_id,
      Roles.membership_administrator_key(),
      Roles.membership_administrator_name()
    )

    insert_role_permission_projection!(
      attrs.club_id,
      attrs.role_id,
      Permissions.club_manage_members()
    )

    insert_role_assignment_projection!(
      attrs.club_id,
      attrs.membership_id,
      attrs.person_id,
      attrs.role_id
    )

    insert_member_permission_projection!(
      attrs.club_id,
      attrs.membership_id,
      attrs.person_id,
      attrs.grant_count
    )

    attrs
  end

  defp canonicalize_admin_role_projection!(club_id, role_id) do
    assert {1, _rows} =
             Repo.update_all(
               from(role in RoleProjection,
                 where: role.club_id == ^club_id and role.role_id == ^role_id
               ),
               set: [
                 role_key: Roles.membership_administrator_key(),
                 name: Roles.membership_administrator_name()
               ]
             )

    :ok
  end

  defp insert_custom_permission_grant!(club_id, membership_id, person_id) do
    role_id = Memba.ID.generate(:role)

    insert_role_projection!(club_id, role_id, "custom", "Custom")
    insert_role_permission_projection!(club_id, role_id, Permissions.club_manage_members())
    insert_role_assignment_projection!(club_id, membership_id, person_id, role_id)
  end

  defp insert_role_projection!(club_id, role_id, role_key, name) do
    now = DateTime.utc_now(:microsecond)

    Repo.insert!(
      %RoleProjection{
        club_id: club_id,
        role_id: role_id,
        role_key: role_key,
        name: name,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: :nothing
    )
  end

  defp insert_role_permission_projection!(club_id, role_id, permission) do
    now = DateTime.utc_now(:microsecond)

    Repo.insert!(
      %RolePermissionProjection{
        club_id: club_id,
        role_id: role_id,
        permission: permission,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: :nothing
    )
  end

  defp insert_role_assignment_projection!(club_id, membership_id, person_id, role_id) do
    now = DateTime.utc_now(:microsecond)

    Repo.insert!(
      %RoleAssignmentProjection{
        club_id: club_id,
        membership_id: membership_id,
        person_id: person_id,
        role_id: role_id,
        active: true,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: :nothing
    )
  end

  defp insert_member_permission_projection!(club_id, membership_id, person_id, grant_count) do
    now = DateTime.utc_now(:microsecond)

    Repo.insert!(
      %MemberPermissionProjection{
        club_id: club_id,
        membership_id: membership_id,
        person_id: person_id,
        permission: Permissions.club_manage_members(),
        grant_count: grant_count,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: :nothing
    )
  end

  defp candidates(report), do: Enum.flat_map(report.clubs, & &1.candidates)

  defp recorded_events(club_id) do
    case EventStore.stream_forward(App, club_id) do
      {:error, :stream_not_found} -> []
      events -> Enum.to_list(events)
    end
  end

  defp appended_event_data(club_id, initial_count) do
    club_id
    |> recorded_events()
    |> Enum.drop(initial_count)
    |> Enum.map(& &1.data)
  end

  defp appended_event_metadata(club_id, initial_count) do
    club_id
    |> recorded_events()
    |> Enum.drop(initial_count)
    |> Enum.map(& &1.metadata)
  end

  defp with_env(env, fun) do
    previous = Map.new(env, fn {key, _value} -> {key, System.get_env(key)} end)

    Enum.each(env, fn {key, value} -> System.put_env(key, value) end)

    try do
      fun.()
    after
      Enum.each(previous, fn
        {key, nil} -> System.delete_env(key)
        {key, value} -> System.put_env(key, value)
      end)
    end
  end
end
