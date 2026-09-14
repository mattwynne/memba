defmodule Memba.Membership.AdminHistoryReconciliation do
  @moduledoc """
  Plans and applies the legacy Admin history reconciliation.

  The runner only uses projected, normalized Admin evidence to choose candidates,
  then asks the Club aggregate command which canonical facts, if any, are missing.

  Each Club aggregate command is atomic. A multi-candidate or multi-club apply run
  is not globally transactional; it is append-only and resumable. Apply mode runs
  all preflight checks before any dispatch and stops on the first dispatch error.
  """

  import Ecto.Query

  alias Commanded.Commands.ExecutionResult
  alias Memba.BuildInfo
  alias Memba.Membership.App
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.ReconcileLegacyAdminHistory
  alias Memba.Membership.Events.ClubRoleAssignedToMember
  alias Memba.Membership.Events.ClubRoleDefined
  alias Memba.Membership.Events.ClubRolePermissionGranted
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.MemberPermission, as: MemberPermissionProjection
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Role, as: RoleProjection
  alias Memba.Membership.Projections.RoleAssignment, as: RoleAssignmentProjection
  alias Memba.Membership.Projections.RolePermission, as: RolePermissionProjection
  alias Memba.Membership.Projectors.Membership, as: MembershipProjector
  alias Memba.Membership.Projectors.Role, as: RoleProjector
  alias Memba.Membership.Roles
  alias Memba.ProjectionBarrier
  alias Memba.Repo

  @acknowledgement "YES_APPEND_MISSING_ADMIN_FACTS"
  @repair_metadata_kind "legacy_admin_history_reconciliation"
  @projection_timeout 60_000
  @plan_source_projectors [MembershipProjector, RoleProjector]

  @doc """
  Build a read-only reconciliation plan.

  Options:

    * `:club_ids` - optional club ID allow-list.
  """
  def plan(opts \\ []) when is_list(opts) do
    await_plan_source_projections!(opts)

    candidates = candidate_rows(opts)
    checked_at = checked_at()

    clubs =
      candidates
      |> Enum.group_by(& &1.club_id)
      |> Enum.sort_by(fn {club_id, _rows} -> club_id end)
      |> Enum.map(fn {club_id, rows} -> plan_club(club_id, rows) end)

    report(:dry_run, checked_at, clubs, %{})
  end

  @doc """
  Run the reconciliation.

  Defaults to dry-run. Apply mode requires explicit safeguards and returns
  `{:error, reason}` before dispatching when they are missing.
  """
  def run(opts \\ []) when is_list(opts) do
    case normalize_mode(Keyword.get(opts, :mode, :dry_run)) do
      {:ok, :dry_run} ->
        {:ok, plan(opts)}

      {:ok, :apply} ->
        with :ok <- validate_apply_safeguards(opts),
             {:ok, report} <- apply(opts) do
          {:ok, report}
        end

      {:error, reason} ->
        {:error, %{error: :invalid_mode, reason: reason}}
    end
  end

  @doc """
  Run the reconciliation, raising on errors.
  """
  def run!(opts \\ []) when is_list(opts) do
    case run(opts) do
      {:ok, report} -> report
      {:error, reason} -> raise RuntimeError, inspect(reason, pretty: true)
    end
  end

  def acknowledgement, do: @acknowledgement

  defp apply(opts) do
    initial_plan = plan(opts)
    checked_at = checked_at()
    repairable_candidates = candidates_with_status(initial_plan, :repairable)

    with :ok <- preflight_apply_plan(initial_plan, opts),
         {:ok, appended_by_key} <- dispatch_repairable_candidates(repairable_candidates, opts) do
      ProjectionBarrier.await!(@plan_source_projectors, timeout: @projection_timeout)

      post_plan = post_apply_plan(opts)

      final_report =
        apply_report(initial_plan, post_plan, checked_at, appended_by_key)

      if post_apply_verified?(
           post_plan,
           MapSet.new(Enum.map(all_candidates(initial_plan), &candidate_key/1))
         ) do
        {:ok, final_report}
      else
        {:error,
         %{
           error: :post_apply_verification_failed,
           reason:
             "not every targeted candidate is already reconciled with the expected grant count",
           report: final_report
         }}
      end
    end
  end

  defp validate_apply_safeguards(opts) do
    reasons =
      []
      |> require_explicit_club_ids(opts)
      |> require_non_empty_string(opts, :operation_id)
      |> require_non_empty_string(opts, :approval_reference)
      |> require_acknowledgement(opts)

    case Enum.reverse(reasons) do
      [] -> :ok
      reasons -> {:error, %{error: :apply_safeguards_failed, reasons: reasons}}
    end
  end

  defp require_explicit_club_ids(reasons, opts) do
    case Keyword.get(opts, :club_ids) do
      club_ids when is_list(club_ids) and club_ids != [] ->
        if Enum.all?(club_ids, &non_empty_string?/1) do
          reasons
        else
          [:club_ids_must_be_non_empty_strings | reasons]
        end

      _missing_or_empty ->
        [:club_ids_required | reasons]
    end
  end

  defp require_non_empty_string(reasons, opts, :operation_id) do
    if non_empty_string?(Keyword.get(opts, :operation_id)) do
      reasons
    else
      [:operation_id_required | reasons]
    end
  end

  defp require_non_empty_string(reasons, opts, :approval_reference) do
    if non_empty_string?(Keyword.get(opts, :approval_reference)) do
      reasons
    else
      [:approval_reference_required | reasons]
    end
  end

  defp require_acknowledgement(reasons, opts) do
    if Keyword.get(opts, :acknowledgement) == @acknowledgement do
      reasons
    else
      [:acknowledgement_required | reasons]
    end
  end

  defp preflight_apply_plan(initial_plan, opts) do
    candidates = all_candidates(initial_plan)
    scoped_club_ids = normalize_club_ids(Keyword.fetch!(opts, :club_ids))
    planned_club_ids = candidates |> Enum.map(& &1.club_id) |> MapSet.new()

    missing_scoped_club_ids =
      scoped_club_ids
      |> Enum.reject(&MapSet.member?(planned_club_ids, &1))

    manual_review_candidates = Enum.filter(candidates, &(&1.status == :manual_review))

    unexpected_status_candidates =
      Enum.reject(candidates, &(&1.status in [:repairable, :already_reconciled, :manual_review]))

    reasons =
      []
      |> maybe_preflight_reason(candidates == [], %{reason: :no_candidates_planned})
      |> maybe_preflight_reason(missing_scoped_club_ids != [], %{
        reason: :scoped_clubs_missing_candidates,
        club_ids: missing_scoped_club_ids
      })
      |> maybe_preflight_reason(manual_review_candidates != [], %{
        reason: :manual_review_candidates_present,
        candidates: Enum.map(manual_review_candidates, &candidate_error_summary/1)
      })
      |> maybe_preflight_reason(unexpected_status_candidates != [], %{
        reason: :unexpected_candidate_statuses,
        candidates: Enum.map(unexpected_status_candidates, &candidate_error_summary/1)
      })
      |> Enum.reverse()

    case reasons do
      [] ->
        :ok

      reasons ->
        {:error,
         %{
           error: :apply_preflight_failed,
           reasons: reasons,
           plan: preflight_plan_summary(initial_plan)
         }}
    end
  end

  defp maybe_preflight_reason(reasons, true, reason), do: [reason | reasons]
  defp maybe_preflight_reason(reasons, false, _reason), do: reasons

  defp preflight_plan_summary(report) do
    %{
      mode: report.mode,
      checked_at: report.checked_at,
      candidate_git_sha: report.candidate_git_sha,
      totals: report.totals,
      clubs:
        Enum.map(report.clubs, fn club ->
          %{
            club_id: club.club_id,
            candidates: Enum.map(club.candidates, &candidate_error_summary/1)
          }
        end)
    }
  end

  defp candidate_error_summary(candidate) do
    %{
      club_id: candidate.club_id,
      membership_id: candidate.membership_id,
      person_id: candidate.person_id,
      status: candidate.status,
      reason: json_safe(candidate.reason),
      events_planned: candidate.events_planned,
      current_grant_count: candidate.current_grant_count,
      expected_grant_count: candidate.expected_grant_count,
      role_id: candidate.role_id,
      expected_role_id: candidate.expected_role_id
    }
  end

  defp json_safe(nil), do: nil
  defp json_safe(value) when is_atom(value), do: value
  defp json_safe(value) when is_binary(value), do: value
  defp json_safe(value) when is_boolean(value), do: value
  defp json_safe(value) when is_number(value), do: value
  defp json_safe(values) when is_list(values), do: Enum.map(values, &json_safe/1)

  defp json_safe(%{} = map) do
    Map.new(map, fn {key, value} -> {json_safe_key(key), json_safe(value)} end)
  end

  defp json_safe(value), do: inspect(value)

  defp json_safe_key(key) when is_atom(key), do: key
  defp json_safe_key(key) when is_binary(key), do: key
  defp json_safe_key(key), do: inspect(key)

  defp dispatch_repairable_candidates(candidates, opts) do
    metadata = %{
      "operation_id" => Keyword.fetch!(opts, :operation_id),
      "approval_reference" => Keyword.fetch!(opts, :approval_reference),
      "repair_kind" => @repair_metadata_kind
    }

    Enum.reduce_while(candidates, {:ok, %{}}, fn candidate, {:ok, appended_by_key} ->
      command = command(candidate)

      dispatch_opts = [
        consistency: [RoleProjector],
        metadata: metadata,
        returning: :execution_result
      ]

      case App.dispatch(command, dispatch_opts) do
        :ok ->
          {:cont,
           {:ok, Map.put(appended_by_key, candidate_key(candidate), candidate.events_planned)}}

        {:ok, %ExecutionResult{events: events}} ->
          {:cont, {:ok, Map.put(appended_by_key, candidate_key(candidate), length(events))}}

        {:ok, _result} ->
          {:cont,
           {:ok, Map.put(appended_by_key, candidate_key(candidate), candidate.events_planned)}}

        {:error, reason} ->
          {:halt,
           {:error,
            %{
              error: :dispatch_failed,
              club_id: candidate.club_id,
              membership_id: candidate.membership_id,
              person_id: candidate.person_id,
              reason: inspect(reason)
            }}}

        other ->
          {:halt,
           {:error,
            %{
              error: :dispatch_failed,
              club_id: candidate.club_id,
              membership_id: candidate.membership_id,
              person_id: candidate.person_id,
              reason: inspect(other)
            }}}
      end
    end)
  end

  defp await_plan_source_projections!(opts) do
    barrier = Keyword.get(opts, :projection_barrier, &ProjectionBarrier.await!/2)
    barrier_opts = [timeout: @projection_timeout]

    case barrier do
      await when is_function(await, 2) ->
        await.(@plan_source_projectors, barrier_opts)

      module when is_atom(module) ->
        module.await!(@plan_source_projectors, barrier_opts)
    end
  end

  defp post_apply_plan(opts) do
    case Keyword.get(opts, :post_apply_plan, &plan/1) do
      plan_fun when is_function(plan_fun, 1) -> plan_fun.(opts)
      plan_fun when is_function(plan_fun, 0) -> plan_fun.()
    end
  end

  defp candidate_rows(opts) do
    club_ids = normalize_club_ids(Keyword.get(opts, :club_ids, []))
    permission = Permissions.club_manage_members()

    RoleAssignmentProjection
    |> join(:inner, [assignment], role in RoleProjection,
      on: role.club_id == assignment.club_id and role.role_id == assignment.role_id
    )
    |> join(:inner, [assignment, _role], role_permission in RolePermissionProjection,
      on:
        role_permission.club_id == assignment.club_id and
          role_permission.role_id == assignment.role_id and
          role_permission.permission == ^permission
    )
    |> join(:inner, [assignment, _role, _role_permission], membership in MembershipProjection,
      on:
        membership.club_id == assignment.club_id and
          membership.membership_id == assignment.membership_id and
          membership.person_id == assignment.person_id and membership.active == true
    )
    |> join(
      :inner,
      [assignment, _role, _role_permission, _membership],
      member_permission in MemberPermissionProjection,
      on:
        member_permission.club_id == assignment.club_id and
          member_permission.membership_id == assignment.membership_id and
          member_permission.person_id == assignment.person_id and
          member_permission.permission == ^permission
    )
    |> where([assignment], assignment.active == true)
    |> where([_assignment, role], role.role_key == ^Roles.membership_administrator_key())
    |> where([_assignment, role], role.name == ^Roles.membership_administrator_name())
    |> maybe_filter_clubs(club_ids)
    |> order_by([assignment],
      asc: assignment.club_id,
      asc: assignment.membership_id,
      asc: assignment.person_id
    )
    |> select([assignment, role, _role_permission, _membership, member_permission], %{
      club_id: assignment.club_id,
      membership_id: assignment.membership_id,
      person_id: assignment.person_id,
      role_id: assignment.role_id,
      projected_role_id: role.role_id,
      current_grant_count: member_permission.grant_count
    })
    |> Repo.all()
    |> Enum.map(&put_expected_role_id/1)
  end

  defp maybe_filter_clubs(query, []), do: query

  defp maybe_filter_clubs(query, club_ids) do
    where(query, [assignment], assignment.club_id in ^club_ids)
  end

  defp normalize_club_ids(club_ids) when is_list(club_ids) do
    club_ids
    |> Enum.filter(&is_binary/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp normalize_club_ids(_), do: []

  defp put_expected_role_id(row) do
    Map.put(row, :expected_role_id, Roles.membership_administrator_role_id(row.club_id))
  end

  defp plan_club(club_id, rows) do
    {planned_rows, _club_state} =
      rows
      |> Enum.sort_by(&{&1.membership_id, &1.person_id})
      |> Enum.reduce({[], App.aggregate_state(Club, club_id)}, fn row, {planned, club_state} ->
        {candidate, next_state} = plan_candidate(row, club_state)
        {[candidate | planned], next_state}
      end)

    %{
      club_id: club_id,
      candidates: Enum.reverse(planned_rows)
    }
  end

  defp plan_candidate(row, %Club{} = club_state) do
    exact_grant_count = exact_active_role_grant_count(row)

    cond do
      row.role_id != row.expected_role_id or row.projected_role_id != row.expected_role_id ->
        {manual_candidate(row, exact_grant_count, :admin_role_id_mismatch), club_state}

      row.current_grant_count != exact_grant_count ->
        {manual_candidate(row, exact_grant_count, :flattened_grant_count_mismatch), club_state}

      true ->
        command = command(row)

        case Club.execute(club_state, command) do
          {:error, reason} ->
            {manual_candidate(row, exact_grant_count, reason), club_state}

          events ->
            events = List.wrap(events)
            missing_facts = Enum.map(events, &missing_fact_name/1)
            status = if missing_facts == [], do: :already_reconciled, else: :repairable

            candidate =
              base_candidate(row, exact_grant_count)
              |> Map.merge(%{
                status: status,
                reason: nil,
                missing_facts: missing_facts,
                events_planned: length(events),
                events_appended: 0
              })

            next_state = Enum.reduce(events, club_state, &Club.apply(&2, &1))
            {candidate, next_state}
        end
    end
  end

  defp plan_candidate(row, club_state) do
    exact_grant_count = exact_active_role_grant_count(row)
    {manual_candidate(row, exact_grant_count, :club_not_found), club_state}
  end

  defp manual_candidate(row, exact_grant_count, reason) do
    row
    |> base_candidate(exact_grant_count)
    |> Map.merge(%{
      status: :manual_review,
      reason: reason,
      missing_facts: [],
      events_planned: 0,
      events_appended: 0
    })
  end

  defp base_candidate(row, exact_grant_count) do
    %{
      club_id: row.club_id,
      membership_id: row.membership_id,
      person_id: row.person_id,
      current_grant_count: row.current_grant_count,
      expected_grant_count: exact_grant_count,
      role_id: row.role_id,
      expected_role_id: row.expected_role_id
    }
  end

  defp exact_active_role_grant_count(row) do
    permission = Permissions.club_manage_members()

    RoleAssignmentProjection
    |> join(:inner, [assignment], role_permission in RolePermissionProjection,
      on:
        role_permission.club_id == assignment.club_id and
          role_permission.role_id == assignment.role_id and
          role_permission.permission == ^permission
    )
    |> where([assignment], assignment.club_id == ^row.club_id)
    |> where([assignment], assignment.membership_id == ^row.membership_id)
    |> where([assignment], assignment.person_id == ^row.person_id)
    |> where([assignment], assignment.active == true)
    |> select([assignment], count(assignment.role_id, :distinct))
    |> Repo.one()
  end

  defp command(row) do
    %ReconcileLegacyAdminHistory{
      club_id: row.club_id,
      membership_id: row.membership_id,
      person_id: row.person_id
    }
  end

  defp missing_fact_name(%ClubRoleDefined{}), do: "club_role_defined"
  defp missing_fact_name(%ClubRolePermissionGranted{}), do: "club_role_permission_granted"
  defp missing_fact_name(%ClubRoleAssignedToMember{}), do: "club_role_assigned_to_member"

  defp missing_fact_name(event),
    do: event.__struct__ |> Module.split() |> List.last() |> Macro.underscore()

  defp report(mode, checked_at, clubs, appended_by_key) do
    clubs = merge_appended_counts(clubs, appended_by_key)
    candidates = all_candidates(%{clubs: clubs})

    candidate_git_sha = git_sha()

    %{
      mode: mode,
      checked_at: checked_at,
      candidate_git_sha: candidate_git_sha,
      git_sha: candidate_git_sha,
      totals: %{
        clubs: length(clubs),
        candidates: length(candidates),
        repairable: count_status(candidates, :repairable),
        already_reconciled: count_status(candidates, :already_reconciled),
        manual_review: count_status(candidates, :manual_review),
        post_apply_missing_candidate: count_status(candidates, :post_apply_missing_candidate),
        events_planned: Enum.sum(Enum.map(candidates, & &1.events_planned)),
        events_appended: Enum.sum(Enum.map(candidates, & &1.events_appended))
      },
      clubs: clubs
    }
  end

  defp apply_report(initial_plan, post_plan, checked_at, appended_by_key) do
    initial_candidates = all_candidates(initial_plan)
    initial_by_key = Map.new(initial_candidates, &{candidate_key(&1), &1})

    post_candidates =
      post_plan
      |> all_candidates()
      |> Enum.map(fn candidate ->
        key = candidate_key(candidate)
        initial = Map.get(initial_by_key, key, candidate)

        candidate
        |> Map.put(:events_planned, initial.events_planned)
        |> Map.put(:events_appended, Map.get(appended_by_key, key, 0))
      end)

    post_keys = MapSet.new(Enum.map(post_candidates, &candidate_key/1))

    missing_initial_candidates =
      initial_candidates
      |> Enum.reject(&(candidate_key(&1) in post_keys))
      |> Enum.map(fn candidate ->
        key = candidate_key(candidate)

        candidate
        |> Map.put(:status, :post_apply_missing_candidate)
        |> Map.put(:reason, :post_apply_missing_candidate)
        |> Map.put(:missing_facts, [])
        |> Map.put(:events_appended, Map.get(appended_by_key, key, 0))
      end)

    clubs =
      (post_candidates ++ missing_initial_candidates)
      |> Enum.group_by(& &1.club_id)
      |> Enum.sort_by(fn {club_id, _candidates} -> club_id end)
      |> Enum.map(fn {club_id, candidates} ->
        %{
          club_id: club_id,
          candidates: Enum.sort_by(candidates, &{&1.membership_id, &1.person_id})
        }
      end)

    report(:apply, checked_at, clubs, %{})
  end

  defp merge_appended_counts(clubs, appended_by_key) when map_size(appended_by_key) == 0,
    do: clubs

  defp merge_appended_counts(clubs, appended_by_key) do
    Enum.map(clubs, fn club ->
      candidates =
        Enum.map(club.candidates, fn candidate ->
          Map.put(
            candidate,
            :events_appended,
            Map.get(appended_by_key, candidate_key(candidate), 0)
          )
        end)

      %{club | candidates: candidates}
    end)
  end

  defp all_candidates(report) do
    report.clubs
    |> Enum.flat_map(& &1.candidates)
    |> Enum.sort_by(&{&1.club_id, &1.membership_id, &1.person_id})
  end

  defp candidates_with_status(report, status) do
    report
    |> all_candidates()
    |> Enum.filter(&(&1.status == status))
  end

  defp count_status(candidates, status) do
    Enum.count(candidates, &(&1.status == status))
  end

  defp post_apply_verified?(post_plan, target_keys) do
    post_by_key = Map.new(all_candidates(post_plan), &{candidate_key(&1), &1})

    Enum.all?(target_keys, fn key ->
      case Map.get(post_by_key, key) do
        %{status: :already_reconciled, current_grant_count: count, expected_grant_count: count} ->
          true

        _other ->
          false
      end
    end)
  end

  defp candidate_key(candidate) do
    {candidate.club_id, candidate.membership_id, candidate.person_id}
  end

  defp normalize_mode(:dry_run), do: {:ok, :dry_run}
  defp normalize_mode(:apply), do: {:ok, :apply}
  defp normalize_mode("dry-run"), do: {:ok, :dry_run}
  defp normalize_mode("dry_run"), do: {:ok, :dry_run}
  defp normalize_mode("apply"), do: {:ok, :apply}
  defp normalize_mode(other), do: {:error, "expected :dry_run or :apply, got #{inspect(other)}"}

  defp checked_at, do: DateTime.utc_now(:second) |> DateTime.to_iso8601()

  defp git_sha do
    case BuildInfo.git_sha() do
      {:ok, sha} -> sha
      :error -> nil
    end
  end

  defp non_empty_string?(value), do: is_binary(value) and String.trim(value) != ""
end
