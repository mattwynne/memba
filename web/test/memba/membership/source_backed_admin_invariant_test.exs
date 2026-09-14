defmodule Memba.Membership.SourceBackedAdminInvariantTest do
  use Memba.DataCase, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias Memba.Membership.SourceBackedAdminInvariant

  @club_member_added "Elixir.Memba.Membership.Events.ClubMemberAdded"
  @club_role_assigned "Elixir.Memba.Membership.Events.ClubRoleAssignedToMember"
  @club_role_removed "Elixir.Memba.Membership.Events.ClubRoleRemovedFromMember"

  setup do
    Memba.EventSourcedCase.reset_event_sourced_system!()

    on_exit(fn ->
      Memba.EventSourcedCase.reset_event_sourced_system!()
    end)
  end

  test "empty and healthy projection states pass" do
    assert_pass(run_check())

    ids = healthy_club!()

    report = run_check()

    assert_pass(report)
    assert report["checks"]["active_membership_source_facts"]["violations"] == []
    assert report["checks"]["populated_club_admin_source_backing"]["violations"] == []
    assert ids.admin_role_id == deterministic_admin_role_id(ids.club_id)
  end

  test "projection-only Admin assignment fails check 2" do
    ids = healthy_club!(admin_event?: false)

    report = run_check()

    assert_check_count(report, "active_membership_source_facts", 0)
    assert_check_count(report, "populated_club_admin_source_backing", 1)

    assert [violation] = report["checks"]["populated_club_admin_source_backing"]["violations"]
    assert violation["club_id"] == ids.club_id
    assert violation["active_member_count"] == 1
    assert violation["expected_admin_role_id"] == ids.admin_role_id
  end

  test "active membership projection without source fact fails check 1" do
    ids = ids()
    insert_membership!(ids, active: true)
    insert_admin_assignment!(ids, active: true)
    append_admin_assigned!(ids)

    report = run_check()

    assert_check_count(report, "active_membership_source_facts", 1)
    assert_check_count(report, "populated_club_admin_source_backing", 0)

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

  test "assignment event on another stream does not back the projected Admin" do
    ids = healthy_club!(admin_event?: false)
    other_stream = Memba.ID.generate(:club)
    append_admin_assigned!(ids, stream_uuid: other_stream)

    report = run_check()

    assert_check_count(report, "populated_club_admin_source_backing", 1)
  end

  test "latest Admin removal event does not back the projected Admin" do
    ids = healthy_club!()
    append_event!(ids.club_id, @club_role_removed, admin_payload(ids))

    report = run_check()

    assert_check_count(report, "populated_club_admin_source_backing", 1)
  end

  test "person mismatch in the source assignment does not back the projected Admin" do
    ids = healthy_club!(admin_event?: false)
    mismatched = %{ids | person_id: Memba.ID.generate(:person)}
    append_admin_assigned!(mismatched, stream_uuid: ids.club_id)

    report = run_check()

    assert_check_count(report, "populated_club_admin_source_backing", 1)
  end

  test "non-deterministic roles do not satisfy the Admin invariant" do
    ids = ids(admin_role_id: Memba.ID.generate(:role))
    insert_membership!(ids, active: true)
    append_member_added!(ids)
    insert_admin_assignment!(ids, active: true)
    append_admin_assigned!(ids)

    report = run_check()

    assert_check_count(report, "active_membership_source_facts", 0)
    assert_check_count(report, "populated_club_admin_source_backing", 1)
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

    insert_membership!(ids, active: true)
    append_member_added!(ids)
    insert_admin_assignment!(ids, active: true)

    if Keyword.get(opts, :admin_event?, true) do
      append_admin_assigned!(ids)
    end

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

  defp append_member_added!(ids) do
    append_event!(ids.club_id, @club_member_added, %{
      "club_id" => ids.club_id,
      "membership_id" => ids.membership_id,
      "person_id" => ids.person_id
    })
  end

  defp append_admin_assigned!(ids, opts \\ []) do
    stream_uuid = Keyword.get(opts, :stream_uuid, ids.club_id)
    append_event!(stream_uuid, @club_role_assigned, admin_payload(ids))
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
    assert_check_count(report, "populated_club_admin_source_backing", 0)
  end

  defp assert_check_count(report, check_name, expected_count) do
    assert report["checks"][check_name]["violation_count"] == expected_count
  end
end
