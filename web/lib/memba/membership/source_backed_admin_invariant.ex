defmodule Memba.Membership.SourceBackedAdminInvariant do
  @moduledoc """
  Read-only source-backed Admin invariant check for the iteration 059 cutover.
  """

  alias Memba.BuildInfo
  alias Memba.Repo

  @type report :: map()

  @spec check(keyword()) :: report()
  def check(opts \\ []) when is_list(opts) do
    phase = opts[:phase]

    case run_transaction(phase) do
      {:ok, report} ->
        report

      {:error, %{message: _message, type: _type} = error} ->
        execution_error_report(error, phase)

      {:error, reason} ->
        execution_error_report(%{type: :transaction_error, message: inspect(reason)}, phase)
    end
  end

  @spec check!(keyword()) :: report()
  def check!(opts \\ []) when is_list(opts) do
    report = check(opts)

    cond do
      Map.has_key?(report, "error") ->
        raise RuntimeError,
              "source-backed Admin invariant execution failed: #{Jason.encode!(report)}"

      report["transaction_read_only"] != "on" ->
        raise RuntimeError,
              "source-backed Admin invariant transaction was not read-only: #{Jason.encode!(report)}"

      not event_store_payload_columns_bytea?(report) ->
        raise RuntimeError,
              "source-backed Admin invariant EventStore payload columns are not bytea: #{Jason.encode!(report)}"

      not zero_violations?(report) ->
        raise RuntimeError,
              "source-backed Admin invariant violations detected: #{Jason.encode!(report)}"

      true ->
        report
    end
  end

  defp run_transaction(phase) do
    Repo.transaction(
      fn ->
        Repo.query!("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY", [])

        preflight = one_row!(preflight_sql())
        columns = columns!()

        checks =
          if bytea_columns?(columns) do
            %{
              "active_membership_source_facts" => check_result!(active_membership_source_sql()),
              "populated_club_complete_admin_source_backing" =>
                check_result!(populated_club_admin_sql())
            }
          else
            %{
              "active_membership_source_facts" =>
                skipped_check("event_store_payload_columns_not_bytea"),
              "populated_club_complete_admin_source_backing" =>
                skipped_check("event_store_payload_columns_not_bytea")
            }
          end

        preflight
        |> base_report(columns, checks, phase)
        |> Map.put(
          "pass",
          transaction_read_only?(preflight) and bytea_columns?(columns) and checks_pass?(checks)
        )
      end,
      timeout: :infinity
    )
  rescue
    exception -> {:error, %{type: exception.__struct__, message: Exception.message(exception)}}
  catch
    kind, reason -> {:error, %{type: kind, message: inspect(reason)}}
  end

  defp preflight_sql do
    ~S"""
    SELECT
      current_database() AS database_name,
      current_setting('transaction_read_only') AS transaction_read_only,
      to_char(
        statement_timestamp() AT TIME ZONE 'UTC',
        'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'
      ) AS checked_at_utc
    """
  end

  defp columns! do
    Repo.query!(
      ~S"""
      SELECT
        column_name,
        data_type
      FROM information_schema.columns
      WHERE table_schema = 'event_store'
        AND table_name = 'events'
        AND column_name IN ('data', 'metadata')
      ORDER BY column_name
      """,
      []
    ).rows
    |> Enum.map(fn [column_name, data_type] ->
      %{"column_name" => column_name, "data_type" => data_type}
    end)
  end

  defp active_membership_source_sql do
    ~S"""
    WITH active_membership_hashes AS (
      SELECT
        membership.club_id,
        membership.membership_id,
        membership.person_id,
        md5(
          convert_to('system-group', 'UTF8')
          || decode('00', 'hex')
          || convert_to(membership.club_id, 'UTF8')
          || decode('00', 'hex')
          || convert_to('everyone', 'UTF8')
        ) AS everyone_group_hash
      FROM membership_memberships AS membership
      WHERE membership.active
    ),
    active_memberships AS (
      SELECT
        club_id,
        membership_id,
        person_id,
        'grp_'
          || substr(everyone_group_hash, 1, 8)
          || '-'
          || substr(everyone_group_hash, 9, 4)
          || '-'
          || substr(everyone_group_hash, 13, 4)
          || '-'
          || substr(everyone_group_hash, 17, 4)
          || '-'
          || substr(everyone_group_hash, 21, 12)
          AS expected_everyone_group_id
      FROM active_membership_hashes
    ),
    club_events AS (
      SELECT
        stream.stream_uuid AS club_id,
        stream_event.stream_version,
        event.event_type,
        convert_from(event.data, 'UTF8')::jsonb AS event_data
      FROM event_store.events AS event
      JOIN event_store.stream_events AS stream_event
        ON stream_event.event_id = event.event_id
      JOIN event_store.streams AS stream
        ON stream.stream_id = stream_event.stream_id
      WHERE stream.stream_uuid LIKE 'clb\_%' ESCAPE '\'
        AND event.event_type IN (
          'Elixir.Memba.Membership.Events.ClubMemberAdded',
          'Elixir.Memba.Membership.Events.ClubMemberRemoved',
          'Elixir.Memba.Membership.Events.MemberAdded',
          'Elixir.Memba.Membership.Events.MemberRemoved',
          'Elixir.Memba.Membership.Events.GroupMemberAdded',
          'Elixir.Memba.Membership.Events.GroupMemberRemoved'
        )
    ),
    source_fact_violations AS (
      SELECT
        membership.club_id,
        membership.membership_id,
        membership.person_id,
        membership.expected_everyone_group_id
      FROM active_memberships AS membership
      WHERE COALESCE(
        (
          SELECT
            (
              event.event_type IN (
                'Elixir.Memba.Membership.Events.ClubMemberAdded',
                'Elixir.Memba.Membership.Events.MemberAdded'
              )
              AND event.event_data ->> 'club_id' = membership.club_id
              AND event.event_data ->> 'person_id' = membership.person_id
            ) IS TRUE
          FROM club_events AS event
          WHERE event.club_id = membership.club_id
            AND event.event_data ->> 'membership_id' =
              membership.membership_id
            AND event.event_type IN (
              'Elixir.Memba.Membership.Events.ClubMemberAdded',
              'Elixir.Memba.Membership.Events.ClubMemberRemoved',
              'Elixir.Memba.Membership.Events.MemberAdded',
              'Elixir.Memba.Membership.Events.MemberRemoved'
            )
          ORDER BY event.stream_version DESC
          LIMIT 1
        ),
        (
          SELECT
            (
              event.event_type =
                'Elixir.Memba.Membership.Events.GroupMemberAdded'
              AND event.event_data ->> 'club_id' = membership.club_id
              AND event.event_data ->> 'person_id' = membership.person_id
            ) IS TRUE
          FROM club_events AS event
          WHERE event.club_id = membership.club_id
            AND event.event_data ->> 'membership_id' =
              membership.membership_id
            AND event.event_data ->> 'group_id' =
              membership.expected_everyone_group_id
            AND event.event_type IN (
              'Elixir.Memba.Membership.Events.GroupMemberAdded',
              'Elixir.Memba.Membership.Events.GroupMemberRemoved'
            )
          ORDER BY event.stream_version DESC
          LIMIT 1
        ),
        false
      ) IS NOT TRUE
    )
    SELECT
      count(*) AS violation_count,
      COALESCE(
        jsonb_agg(
          jsonb_build_object(
            'club_id', violation.club_id,
            'membership_id', violation.membership_id,
            'person_id', violation.person_id,
            'expected_everyone_group_id',
              violation.expected_everyone_group_id
          )
          ORDER BY violation.club_id, violation.membership_id
        ),
        '[]'::jsonb
      ) AS violations
    FROM source_fact_violations AS violation
    """
  end

  defp populated_club_admin_sql do
    ~S"""
    WITH populated_club_hashes AS (
      SELECT
        membership.club_id,
        count(*) AS active_member_count,
        md5(
          convert_to('membership_administrator', 'UTF8')
          || decode('00', 'hex')
          || convert_to(membership.club_id, 'UTF8')
        ) AS admin_role_hash
      FROM membership_memberships AS membership
      WHERE membership.active
      GROUP BY membership.club_id
    ),
    populated_clubs AS (
      SELECT
        club_id,
        active_member_count,
        'rol_'
          || substr(admin_role_hash, 1, 8)
          || '-'
          || substr(admin_role_hash, 9, 4)
          || '-'
          || substr(admin_role_hash, 13, 4)
          || '-'
          || substr(admin_role_hash, 17, 4)
          || '-'
          || substr(admin_role_hash, 21, 12)
          AS expected_admin_role_id
      FROM populated_club_hashes
    ),
    club_admin_source_facts AS (
      SELECT
        stream.stream_uuid AS club_id,
        stream_event.stream_version,
        event.event_type,
        convert_from(event.data, 'UTF8')::jsonb AS event_data
      FROM event_store.events AS event
      JOIN event_store.stream_events AS stream_event
        ON stream_event.event_id = event.event_id
      JOIN event_store.streams AS stream
        ON stream.stream_id = stream_event.stream_id
      WHERE stream.stream_uuid LIKE 'clb\_%' ESCAPE '\'
        AND event.event_type IN (
          'Elixir.Memba.Membership.Events.ClubRoleDefined',
          'Elixir.Memba.Membership.Events.ClubRolePermissionGranted',
          'Elixir.Memba.Membership.Events.ClubRoleAssignedToMember',
          'Elixir.Memba.Membership.Events.ClubRoleRemovedFromMember',
          'Elixir.Memba.Membership.Events.MemberRoleAssigned',
          'Elixir.Memba.Membership.Events.MemberRoleRemoved'
        )
    ),
    complete_admin_candidates AS (
      SELECT
        club.club_id,
        club.active_member_count,
        club.expected_admin_role_id,
        membership.membership_id,
        membership.person_id,
        member_permission.grant_count AS flattened_grant_count,
        (
          SELECT count(DISTINCT exact_assignment.role_id)
          FROM membership_role_assignments AS exact_assignment
          JOIN membership_role_permissions AS exact_permission
            ON exact_permission.club_id = exact_assignment.club_id
            AND exact_permission.role_id = exact_assignment.role_id
            AND exact_permission.permission = 'club.manage_members'
          WHERE exact_assignment.club_id = membership.club_id
            AND exact_assignment.membership_id = membership.membership_id
            AND exact_assignment.person_id = membership.person_id
            AND exact_assignment.active
        ) AS exact_active_grant_count
      FROM populated_clubs AS club
      JOIN membership_memberships AS membership
        ON membership.club_id = club.club_id
        AND membership.active
      JOIN membership_roles AS role
        ON role.club_id = club.club_id
        AND role.role_id = club.expected_admin_role_id
        AND role.role_key = 'admin'
        AND role.name = 'Admin'
      JOIN membership_role_permissions AS role_permission
        ON role_permission.club_id = club.club_id
        AND role_permission.role_id = club.expected_admin_role_id
        AND role_permission.permission = 'club.manage_members'
      JOIN membership_role_assignments AS assignment
        ON assignment.club_id = club.club_id
        AND assignment.membership_id = membership.membership_id
        AND assignment.person_id = membership.person_id
        AND assignment.role_id = club.expected_admin_role_id
        AND assignment.active
      JOIN membership_member_permissions AS member_permission
        ON member_permission.club_id = membership.club_id
        AND member_permission.membership_id = membership.membership_id
        AND member_permission.person_id = membership.person_id
        AND member_permission.permission = 'club.manage_members'
        AND member_permission.grant_count > 0
    ),
    source_backed_admin_candidates AS (
      SELECT candidate.*
      FROM complete_admin_candidates AS candidate
      WHERE candidate.flattened_grant_count = candidate.exact_active_grant_count
        AND candidate.exact_active_grant_count > 0
        AND EXISTS (
          SELECT 1
          FROM club_admin_source_facts AS fact
          WHERE fact.club_id = candidate.club_id
            AND fact.event_type =
              'Elixir.Memba.Membership.Events.ClubRoleDefined'
            AND fact.event_data ->> 'club_id' = candidate.club_id
            AND fact.event_data ->> 'role_id' = candidate.expected_admin_role_id
        )
        AND EXISTS (
          SELECT 1
          FROM club_admin_source_facts AS fact
          WHERE fact.club_id = candidate.club_id
            AND fact.event_type =
              'Elixir.Memba.Membership.Events.ClubRolePermissionGranted'
            AND fact.event_data ->> 'club_id' = candidate.club_id
            AND fact.event_data ->> 'role_id' = candidate.expected_admin_role_id
            AND fact.event_data ->> 'permission' = 'club.manage_members'
        )
        AND COALESCE(
          (
            SELECT
              (
                fact.event_type IN (
                  'Elixir.Memba.Membership.Events.ClubRoleAssignedToMember',
                  'Elixir.Memba.Membership.Events.MemberRoleAssigned'
                )
                AND fact.event_data ->> 'club_id' = candidate.club_id
                AND fact.event_data ->> 'person_id' = candidate.person_id
              ) IS TRUE
            FROM club_admin_source_facts AS fact
            WHERE fact.club_id = candidate.club_id
              AND fact.event_type IN (
                'Elixir.Memba.Membership.Events.ClubRoleAssignedToMember',
                'Elixir.Memba.Membership.Events.ClubRoleRemovedFromMember',
                'Elixir.Memba.Membership.Events.MemberRoleAssigned',
                'Elixir.Memba.Membership.Events.MemberRoleRemoved'
              )
              AND fact.event_data ->> 'membership_id' = candidate.membership_id
              AND fact.event_data ->> 'role_id' = candidate.expected_admin_role_id
            ORDER BY fact.stream_version DESC
            LIMIT 1
          ),
          false
        )
    ),
    admin_invariant_violations AS (
      SELECT
        club.club_id,
        club.active_member_count,
        club.expected_admin_role_id
      FROM populated_clubs AS club
      WHERE NOT EXISTS (
        SELECT 1
        FROM source_backed_admin_candidates AS candidate
        WHERE candidate.club_id = club.club_id
      )
    )
    SELECT
      count(*) AS violation_count,
      COALESCE(
        jsonb_agg(
          jsonb_build_object(
            'club_id', violation.club_id,
            'active_member_count', violation.active_member_count,
            'expected_admin_role_id', violation.expected_admin_role_id
          )
          ORDER BY violation.club_id
        ),
        '[]'::jsonb
      ) AS violations
    FROM admin_invariant_violations AS violation
    """
  end

  defp one_row!(sql) do
    sql
    |> Repo.query!([])
    |> Map.fetch!(:rows)
    |> case do
      [row] -> row
    end
  end

  defp check_result!(sql) do
    [violation_count, violations] = one_row!(sql)

    %{
      "violation_count" => violation_count,
      "violations" => normalize_jsonb(violations)
    }
  end

  defp skipped_check(reason) do
    %{"violation_count" => nil, "violations" => [], "skipped" => reason}
  end

  defp base_report([database_name, transaction_read_only, checked_at_utc], columns, checks, phase) do
    %{
      "database_name" => database_name,
      "transaction_read_only" => transaction_read_only,
      "checked_at_utc" => checked_at_utc,
      "event_store_columns" => columns,
      "git_sha" => git_sha(),
      "checks" => checks
    }
    |> maybe_put_phase(phase)
  end

  defp execution_error_report(error, phase) do
    %{
      "pass" => false,
      "git_sha" => git_sha(),
      "error" => %{
        "type" => inspect(error.type),
        "message" => error.message
      }
    }
    |> maybe_put_phase(phase)
  end

  defp maybe_put_phase(report, nil), do: report
  defp maybe_put_phase(report, ""), do: report
  defp maybe_put_phase(report, phase), do: Map.put(report, "phase", phase)

  defp git_sha do
    case BuildInfo.git_sha() do
      {:ok, sha} -> sha
      :error -> nil
    end
  end

  defp transaction_read_only?([_database_name, transaction_read_only, _checked_at_utc]) do
    transaction_read_only == "on"
  end

  defp event_store_payload_columns_bytea?(report) do
    report
    |> Map.get("event_store_columns", [])
    |> bytea_columns?()
  end

  defp bytea_columns?(columns) when is_list(columns) do
    column_types = Map.new(columns, &{&1["column_name"], &1["data_type"]})
    column_types == %{"data" => "bytea", "metadata" => "bytea"}
  end

  defp zero_violations?(report) do
    report
    |> Map.fetch!("checks")
    |> checks_pass?()
  end

  defp checks_pass?(checks) do
    Enum.all?(checks, fn {_name, check} -> check["violation_count"] == 0 end)
  end

  defp normalize_jsonb(value) when is_binary(value), do: Jason.decode!(value)
  defp normalize_jsonb(value), do: value
end
