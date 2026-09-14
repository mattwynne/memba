defmodule Memba.Membership.SourceBackedAdminInvariantTest do
  use Memba.DataCase, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias Memba.Membership.SourceBackedAdminInvariant

  @admin_check "populated_club_complete_admin_source_backing"
  @club_manage_members "club.manage_members"
  @club_member_added "Elixir.Memba.Membership.Events.ClubMemberAdded"
  @club_role_defined "Elixir.Memba.Membership.Events.ClubRoleDefined"
  @club_role_permission_granted "Elixir.Memba.Membership.Events.ClubRolePermissionGranted"
  @club_role_assigned "Elixir.Memba.Membership.Events.ClubRoleAssignedToMember"
  @club_role_removed "Elixir.Memba.Membership.Events.ClubRoleRemovedFromMember"
  @legacy_member_role_assigned "Elixir.Memba.Membership.Events.MemberRoleAssigned"

  setup do
    Memba.EventSourcedCase.reset_event_sourced_system!()

    on_exit(fn ->
      Memba.EventSourcedCase.reset_event_sourced_system!()
    end)
  end

  test "empty and healthy complete histories pass" do
    assert_pass(run_check())

    ids = healthy_club!()

    report = run_check()

    assert_pass(report)
    assert report["checks"]["active_membership_source_facts"]["violations"] == []
    assert report["checks"][@admin_check]["violations"] == []
    assert ids.admin_role_id == deterministic_admin_role_id(ids.club_id)
  end

  test "legacy assignment events remain compatible when ordinary role facts are present" do
    ids = healthy_club!(assignment_event_type: @legacy_member_role_assigned)

    assert_pass(run_check())
    assert ids.admin_role_id == deterministic_admin_role_id(ids.club_id)
  end

  test "assignment-only Admin backing fails check 2" do
    ids = populated_club!()
    insert_admin_assignment!(ids, active: true)
    append_admin_assigned!(ids)

    report = run_check()

    assert_check_count(report, "active_membership_source_facts", 0)
    assert_check_count(report, @admin_check, 1)

    assert [violation] = report["checks"][@admin_check]["violations"]
    assert violation["club_id"] == ids.club_id
    assert violation["active_member_count"] == 1
    assert violation["expected_admin_role_id"] == ids.admin_role_id
  end

  test "role-only Admin backing fails check 2" do
    ids = populated_club!()
    insert_admin_role!(ids)
    append_admin_role_defined!(ids)

    assert_check_count(run_check(), @admin_check, 1)
  end

  test "role and permission without assignment fail check 2" do
    ids = populated_club!()
    insert_admin_role!(ids)
    insert_admin_role_permission!(ids)
    append_admin_role_defined!(ids)
    append_admin_role_permission_granted!(ids)

    assert_check_count(run_check(), @admin_check, 1)
  end

  test "active membership projection without source fact fails check 1" do
    ids = ids()
    insert_membership!(ids, active: true)
    insert_complete_admin_projection!(ids)
    append_complete_admin_source_facts!(ids)

    report = run_check()

    assert_check_count(report, "active_membership_source_facts", 1)
    assert_check_count(report, @admin_check, 0)

    assert [violation] = report["checks"]["active_membership_source_facts"]["violations"]
    assert violation["club_id"] == ids.club_id
    assert violation["membership_id"] == ids.membership_id
    assert violation["person_id"] == ids.person_id
    assert violation["expected_everyone_group_id"] == deterministic_everyone_group_id(ids.club_id)
  end

  test "inactive memberships are ignored" do
    ids = ids()
    insert_membership!(ids, active: false)

    assert_pass(run_check())
  end

  test "projection/source partial combinations fail check 2" do
    missing_role_source = healthy_club!(role_source?: false)
    missing_permission_source = healthy_club!(permission_source?: false)
    missing_assignment_source = healthy_club!(assignment_source?: false)

    report = run_check()

    assert_check_count(report, @admin_check, 3)

    violating_club_ids = violation_club_ids(report, @admin_check)
    assert missing_role_source.club_id in violating_club_ids
    assert missing_permission_source.club_id in violating_club_ids
    assert missing_assignment_source.club_id in violating_club_ids
  end

  test "wrong stream or payload identity in ordinary role facts fails check 2" do
    wrong_role_stream = healthy_club!(role_source?: false)
    append_admin_role_defined!(wrong_role_stream, stream_uuid: Memba.ID.generate(:club))

    wrong_permission_payload = healthy_club!(permission_source?: false)

    append_admin_role_permission_granted!(
      %{
        wrong_permission_payload
        | club_id: Memba.ID.generate(:club)
      },
      stream_uuid: wrong_permission_payload.club_id
    )

    report = run_check()

    assert_check_count(report, @admin_check, 2)

    violating_club_ids = violation_club_ids(report, @admin_check)
    assert wrong_role_stream.club_id in violating_club_ids
    assert wrong_permission_payload.club_id in violating_club_ids
  end

  test "assignment event on another stream does not back the projected Admin" do
    ids = healthy_club!(assignment_source?: false)
    other_stream = Memba.ID.generate(:club)
    append_admin_assigned!(ids, stream_uuid: other_stream)

    report = run_check()

    assert_check_count(report, @admin_check, 1)
  end

  test "latest Admin removal event does not back the projected Admin" do
    ids = healthy_club!()
    append_event!(ids.club_id, @club_role_removed, admin_payload(ids))

    report = run_check()

    assert_check_count(report, @admin_check, 1)
  end

  test "person mismatch in the source assignment does not back the projected Admin" do
    ids = healthy_club!(assignment_source?: false)
    mismatched = %{ids | person_id: Memba.ID.generate(:person)}
    append_admin_assigned!(mismatched, stream_uuid: ids.club_id)

    report = run_check()

    assert_check_count(report, @admin_check, 1)
  end

  test "non-deterministic roles do not satisfy the Admin invariant" do
    ids = ids(admin_role_id: Memba.ID.generate(:role))
    populated_club!(ids)
    insert_complete_admin_projection!(ids)
    append_complete_admin_source_facts!(ids)

    report = run_check()

    assert_check_count(report, "active_membership_source_facts", 0)
    assert_check_count(report, @admin_check, 1)
  end

  test "missing normalized or flattened projection evidence fails check 2" do
    missing_role_projection = healthy_club!()
    delete_projection_row!("membership_roles", role_id: missing_role_projection.admin_role_id)

    missing_role_permission_projection = healthy_club!()

    delete_projection_row!("membership_role_permissions",
      role_id: missing_role_permission_projection.admin_role_id
    )

    missing_flattened_projection = healthy_club!()

    delete_projection_row!("membership_member_permissions",
      membership_id: missing_flattened_projection.membership_id
    )

    invalid_flattened_projection = healthy_club!()
    set_member_permission_grant_count!(invalid_flattened_projection, 0)

    mismatched_flattened_projection = healthy_club!()
    set_member_permission_grant_count!(mismatched_flattened_projection, 2)

    report = run_check()

    assert_check_count(report, @admin_check, 5)

    violating_club_ids = violation_club_ids(report, @admin_check)
    assert missing_role_projection.club_id in violating_club_ids
    assert missing_role_permission_projection.club_id in violating_club_ids
    assert missing_flattened_projection.club_id in violating_club_ids
    assert invalid_flattened_projection.club_id in violating_club_ids
    assert mismatched_flattened_projection.club_id in violating_club_ids
  end

  test "check! raises when a violation is present" do
    ids = ids()
    insert_membership!(ids, active: true)

    assert_raise RuntimeError, ~r/source-backed Admin invariant violations detected/, fn ->
      run_check!(phase: "test")
    end
  end

  test "report includes metadata and optional phase" do
    previous_sha = System.get_env("MEMBA_GIT_SHA")
    sha = String.duplicate("a", 40)

    System.put_env("MEMBA_GIT_SHA", sha)

    on_exit(fn ->
      if previous_sha do
        System.put_env("MEMBA_GIT_SHA", previous_sha)
      else
        System.delete_env("MEMBA_GIT_SHA")
      end
    end)

    report = run_check(phase: "pre")

    assert_pass(report)
    assert is_binary(report["database_name"])
    assert report["transaction_read_only"] == "on"
    assert String.ends_with?(report["checked_at_utc"], "Z")

    assert report["event_store_columns"] == [
             %{"column_name" => "data", "data_type" => "bytea"},
             %{"column_name" => "metadata", "data_type" => "bytea"}
           ]

    assert report["git_sha"] == sha
    assert report["phase"] == "pre"
  end

  defp healthy_club!(opts \\ []) do
    ids = ids()

    populated_club!(ids)
    insert_complete_admin_projection!(ids)
    append_complete_admin_source_facts!(ids, opts)

    ids
  end

  defp populated_club!(ids \\ ids()) do
    insert_membership!(ids, active: true)
    append_member_added!(ids)
    ids
  end

  defp ids(overrides \\ []) do
    club_id = Keyword.get_lazy(overrides, :club_id, fn -> Memba.ID.generate(:club) end)

    %{
      club_id: club_id,
      membership_id:
        Keyword.get_lazy(overrides, :membership_id, fn -> Memba.ID.generate(:membership) end),
      person_id: Keyword.get_lazy(overrides, :person_id, fn -> Memba.ID.generate(:person) end),
      admin_role_id:
        Keyword.get_lazy(overrides, :admin_role_id, fn -> deterministic_admin_role_id(club_id) end)
    }
  end

  defp deterministic_admin_role_id(club_id) do
    Memba.ID.deterministic(:role, ["membership_administrator", club_id])
  end

  defp deterministic_everyone_group_id(club_id) do
    Memba.ID.deterministic(:group, ["system-group", club_id, "everyone"])
  end

  defp insert_membership!(ids, attrs) do
    active = Keyword.fetch!(attrs, :active)

    persist!(fn ->
      Repo.query!(
        """
        INSERT INTO membership_memberships (
          membership_id,
          club_id,
          person_id,
          active,
          inserted_at,
          updated_at
        )
        VALUES ($1, $2, $3, $4, now(), now())
        """,
        [ids.membership_id, ids.club_id, ids.person_id, active]
      )
    end)
  end

  defp insert_admin_assignment!(ids, attrs) do
    active = Keyword.fetch!(attrs, :active)

    persist!(fn ->
      Repo.query!(
        """
        INSERT INTO membership_role_assignments (
          club_id,
          membership_id,
          person_id,
          role_id,
          active,
          inserted_at,
          updated_at
        )
        VALUES ($1, $2, $3, $4, $5, now(), now())
        """,
        [ids.club_id, ids.membership_id, ids.person_id, ids.admin_role_id, active]
      )
    end)
  end

  defp insert_complete_admin_projection!(ids) do
    insert_admin_role!(ids)
    insert_admin_role_permission!(ids)
    insert_admin_assignment!(ids, active: true)
    insert_admin_member_permission!(ids, 1)
  end

  defp insert_admin_role!(ids) do
    persist!(fn ->
      Repo.query!(
        """
        INSERT INTO membership_roles (
          role_id,
          club_id,
          role_key,
          name,
          inserted_at,
          updated_at
        )
        VALUES ($1, $2, 'admin', 'Admin', now(), now())
        """,
        [ids.admin_role_id, ids.club_id]
      )
    end)
  end

  defp insert_admin_role_permission!(ids) do
    persist!(fn ->
      Repo.query!(
        """
        INSERT INTO membership_role_permissions (
          club_id,
          role_id,
          permission,
          inserted_at,
          updated_at
        )
        VALUES ($1, $2, $3, now(), now())
        """,
        [ids.club_id, ids.admin_role_id, @club_manage_members]
      )
    end)
  end

  defp insert_admin_member_permission!(ids, grant_count) do
    persist!(fn ->
      Repo.query!(
        """
        INSERT INTO membership_member_permissions (
          club_id,
          membership_id,
          person_id,
          permission,
          grant_count,
          inserted_at,
          updated_at
        )
        VALUES ($1, $2, $3, $4, $5, now(), now())
        """,
        [ids.club_id, ids.membership_id, ids.person_id, @club_manage_members, grant_count]
      )
    end)
  end

  defp append_member_added!(ids) do
    append_event!(ids.club_id, @club_member_added, %{
      "club_id" => ids.club_id,
      "membership_id" => ids.membership_id,
      "person_id" => ids.person_id
    })
  end

  defp append_complete_admin_source_facts!(ids, opts \\ []) do
    if Keyword.get(opts, :role_source?, true) do
      append_admin_role_defined!(ids)
    end

    if Keyword.get(opts, :permission_source?, true) do
      append_admin_role_permission_granted!(ids)
    end

    if Keyword.get(opts, :assignment_source?, true) do
      append_admin_assigned!(ids,
        event_type: Keyword.get(opts, :assignment_event_type, @club_role_assigned)
      )
    end
  end

  defp append_admin_role_defined!(ids, opts \\ []) do
    stream_uuid = Keyword.get(opts, :stream_uuid, ids.club_id)

    append_event!(stream_uuid, @club_role_defined, %{
      "club_id" => ids.club_id,
      "role_id" => ids.admin_role_id,
      "role_key" => "admin",
      "name" => "Admin"
    })
  end

  defp append_admin_role_permission_granted!(ids, opts \\ []) do
    stream_uuid = Keyword.get(opts, :stream_uuid, ids.club_id)

    append_event!(stream_uuid, @club_role_permission_granted, %{
      "club_id" => ids.club_id,
      "role_id" => ids.admin_role_id,
      "permission" => @club_manage_members
    })
  end

  defp append_admin_assigned!(ids, opts \\ []) do
    stream_uuid = Keyword.get(opts, :stream_uuid, ids.club_id)
    event_type = Keyword.get(opts, :event_type, @club_role_assigned)
    append_event!(stream_uuid, event_type, admin_payload(ids))
  end

  defp admin_payload(ids) do
    %{
      "club_id" => ids.club_id,
      "membership_id" => ids.membership_id,
      "person_id" => ids.person_id,
      "role_id" => ids.admin_role_id
    }
  end

  defp append_event!(stream_uuid, event_type, payload) do
    persist!(fn ->
      Repo.query!(
        """
        WITH ensured_stream AS (
          INSERT INTO event_store.streams (stream_uuid, stream_version)
          VALUES ($1, 0)
          ON CONFLICT (stream_uuid) DO NOTHING
          RETURNING stream_id
        ),
        selected_stream AS (
          SELECT stream_id FROM ensured_stream
          UNION ALL
          SELECT stream_id
          FROM event_store.streams
          WHERE stream_uuid = $1
          LIMIT 1
        ),
        next_stream_version AS (
          SELECT COALESCE(max(stream_version), 0) + 1 AS stream_version
          FROM event_store.stream_events
          WHERE stream_id = (SELECT stream_id FROM selected_stream)
        ),
        inserted_event AS (
          INSERT INTO event_store.events (
            event_id,
            event_type,
            data,
            metadata
          )
          VALUES ($2::uuid, $3, convert_to($4, 'UTF8'), convert_to('{}', 'UTF8'))
          RETURNING event_id
        )
        INSERT INTO event_store.stream_events (
          event_id,
          stream_id,
          stream_version,
          original_stream_id,
          original_stream_version
        )
        SELECT
          inserted_event.event_id,
          selected_stream.stream_id,
          next_stream_version.stream_version,
          selected_stream.stream_id,
          next_stream_version.stream_version
        FROM inserted_event, selected_stream, next_stream_version
        """,
        [stream_uuid, Ecto.UUID.dump!(Ecto.UUID.generate()), event_type, Jason.encode!(payload)]
      )
    end)
  end

  defp delete_projection_row!(table, where) do
    [{column, value}] = where

    persist!(fn ->
      Repo.query!("DELETE FROM #{table} WHERE #{column} = $1", [value])
    end)
  end

  defp set_member_permission_grant_count!(ids, grant_count) do
    persist!(fn ->
      Repo.query!(
        """
        UPDATE membership_member_permissions
        SET grant_count = $1, updated_at = now()
        WHERE club_id = $2
          AND membership_id = $3
          AND person_id = $4
          AND permission = $5
        """,
        [grant_count, ids.club_id, ids.membership_id, ids.person_id, @club_manage_members]
      )
    end)
  end

  defp violation_club_ids(report, check_name) do
    report["checks"][check_name]["violations"]
    |> Enum.map(& &1["club_id"])
  end

  defp run_check(opts \\ []) do
    persist!(fn -> SourceBackedAdminInvariant.check(opts) end)
  end

  defp run_check!(opts) do
    persist!(fn -> SourceBackedAdminInvariant.check!(opts) end)
  end

  defp persist!(fun) do
    Sandbox.unboxed_run(Repo, fun)
  end

  defp assert_pass(report) do
    assert report["pass"] == true
    assert_check_count(report, "active_membership_source_facts", 0)
    assert_check_count(report, @admin_check, 0)
  end

  defp assert_check_count(report, check_name, expected_count) do
    assert report["checks"][check_name]["violation_count"] == expected_count
  end
end
