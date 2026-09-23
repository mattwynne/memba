defmodule Memba.ReleaseTest do
  use Memba.DataCase, async: false

  alias Memba.Release
  alias Memba.Repo

  @reconciliation_env_vars [
    "MEMBA_GROUP_MEMBERSHIP_RECONCILIATION_MODE",
    "MEMBA_GROUP_MEMBERSHIP_RECONCILIATION_BATCH_SIZE",
    "MEMBA_GROUP_MEMBERSHIP_RECONCILIATION_CLUB_IDS",
    "MEMBA_GROUP_MEMBERSHIP_RECONCILIATION_AFTER",
    "MEMBA_GROUP_MEMBERSHIP_RECONCILIATION_CUTOVER_ACKNOWLEDGEMENT",
    "MEMBA_CONVERSATION_FOLLOW_RECONCILIATION_MODE",
    "MEMBA_CONVERSATION_FOLLOW_RECONCILIATION_BATCH_SIZE",
    "MEMBA_CONVERSATION_FOLLOW_RECONCILIATION_AFTER",
    "MEMBA_CONVERSATION_FOLLOW_RECONCILIATION_PROJECTOR_TIMEOUT",
    "MEMBA_CONVERSATION_FOLLOW_RECONCILIATION_CUTOVER_ACKNOWLEDGEMENT"
  ]

  @release_steps [
    :load_app,
    :init_event_stores,
    :migrate_repos,
    :ensure_release_services_started,
    :await_system_group_backfill_source_projections,
    :run_system_groups_backfill,
    :ensure_production_smoke_fixtures
  ]

  setup do
    original_overrides = Application.get_env(:memba, :release_step_overrides)
    original_env = Map.new(@reconciliation_env_vars, &{&1, System.get_env(&1)})
    Enum.each(@reconciliation_env_vars, &System.delete_env/1)

    on_exit(fn ->
      Enum.each(original_env, fn
        {name, nil} -> System.delete_env(name)
        {name, value} -> System.put_env(name, value)
      end)

      case original_overrides do
        nil -> Application.delete_env(:memba, :release_step_overrides)
        overrides -> Application.put_env(:memba, :release_step_overrides, overrides)
      end
    end)
  end

  test "release migration runs system-group backfill once after migration and source projection catch-up" do
    log = start_supervised!({Agent, fn -> [] end})
    Application.put_env(:memba, :release_step_overrides, recording_overrides(log))

    assert :ok = Release.migrate()

    assert Agent.get(log, & &1) == @release_steps
  end

  test "source-backed Admin invariant remains an external deployment gate" do
    log = start_supervised!({Agent, fn -> [] end})
    Application.put_env(:memba, :release_step_overrides, recording_overrides(log))

    assert :ok = Release.migrate()

    assert Agent.get(log, & &1) == @release_steps
    refute :verify_source_backed_admin_invariant in @release_steps
  end

  test "release migration propagates system-group backfill failures and aborts remaining release work" do
    log = start_supervised!({Agent, fn -> [] end})

    overrides =
      log
      |> recording_overrides()
      |> Keyword.put(:run_system_groups_backfill, fn ->
        record(log, :run_system_groups_backfill)
        raise "system group backfill failed"
      end)
      |> Keyword.put(:ensure_production_smoke_fixtures, fn ->
        flunk("release must abort before production smoke fixtures when backfill fails")
      end)

    Application.put_env(:memba, :release_step_overrides, overrides)

    assert_raise RuntimeError, "system group backfill failed", fn ->
      Release.migrate()
    end

    assert Agent.get(log, & &1) == [
             :load_app,
             :init_event_stores,
             :migrate_repos,
             :ensure_release_services_started,
             :await_system_group_backfill_source_projections,
             :run_system_groups_backfill
           ]
  end

  test "legacy group reconciliation release config fails closed when malformed" do
    Application.put_env(:memba, :release_step_overrides,
      load_app: fn -> :ok end,
      ensure_release_services_started: fn -> :ok end
    )

    for {name, value} <- [
          {"MEMBA_GROUP_MEMBERSHIP_RECONCILIATION_MODE", "maybe"},
          {"MEMBA_GROUP_MEMBERSHIP_RECONCILIATION_BATCH_SIZE", "many"},
          {"MEMBA_GROUP_MEMBERSHIP_RECONCILIATION_AFTER", "not-json"},
          {"MEMBA_GROUP_MEMBERSHIP_RECONCILIATION_CLUB_IDS", " , "}
        ] do
      Enum.each(@reconciliation_env_vars, &System.delete_env/1)
      System.put_env(name, value)

      assert_raise ArgumentError, fn ->
        Release.reconcile_legacy_group_memberships!()
      end
    end

    Enum.each(@reconciliation_env_vars, &System.delete_env/1)
    System.put_env("MEMBA_GROUP_MEMBERSHIP_RECONCILIATION_CLUB_IDS", "not-a-club-id")

    assert_raise RuntimeError, fn ->
      Release.reconcile_legacy_group_memberships!()
    end
  end

  test "legacy conversation-follow reconciliation release config fails closed when malformed" do
    Application.put_env(:memba, :release_step_overrides,
      load_app: fn -> :ok end,
      ensure_release_services_started: fn -> :ok end
    )

    for {name, value} <- [
          {"MEMBA_CONVERSATION_FOLLOW_RECONCILIATION_MODE", "maybe"},
          {"MEMBA_CONVERSATION_FOLLOW_RECONCILIATION_BATCH_SIZE", "many"},
          {"MEMBA_CONVERSATION_FOLLOW_RECONCILIATION_AFTER", "not-json"},
          {"MEMBA_CONVERSATION_FOLLOW_RECONCILIATION_PROJECTOR_TIMEOUT", "later"}
        ] do
      Enum.each(@reconciliation_env_vars, &System.delete_env/1)
      System.put_env(name, value)

      assert_raise ArgumentError, fn ->
        Release.reconcile_legacy_conversation_follows!()
      end
    end
  end

  test "release schema verification passes when migrated tables match application schemas" do
    assert :ok = Release.verify_repo_schema!(Repo)
  end

  test "release schema verification includes system group and conversation access projections" do
    required_tables = [
      {"membership_groups", "release_test_missing_membership_groups"},
      {"membership_group_memberships", "release_test_missing_membership_group_memberships"},
      {"messaging_conversation_group_access", "release_test_missing_conversation_group_access"}
    ]

    Enum.each(required_tables, fn {table, renamed_table} ->
      Repo.query!(~s|ALTER TABLE #{table} RENAME TO #{renamed_table}|, [])

      try do
        assert_raise RuntimeError, ~r/Missing tables:.*#{table}/s, fn ->
          Release.verify_repo_schema!(Repo)
        end
      after
        Repo.query!(~s|ALTER TABLE IF EXISTS #{renamed_table} RENAME TO #{table}|, [])
      end
    end)
  end

  test "release schema verification fails when a recorded migration left the old auth table behind" do
    Repo.query!("ALTER TABLE auth_sign_in_tokens RENAME TO auth_magic_tokens", [])

    assert_raise RuntimeError, ~r/Database schema drift detected after migrations/, fn ->
      Release.verify_repo_schema!(Repo)
    end
  after
    Repo.query!("ALTER TABLE IF EXISTS auth_magic_tokens RENAME TO auth_sign_in_tokens", [])
  end

  defp recording_overrides(log) do
    Enum.map(@release_steps, fn step -> {step, fn -> record(log, step) end} end)
  end

  defp record(log, step) do
    Agent.update(log, &(&1 ++ [step]))
  end
end
