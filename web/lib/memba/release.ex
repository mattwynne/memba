defmodule Memba.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :memba

  def migrate do
    run_release_step(:load_app, &load_app/0)
    run_release_step(:init_event_stores, &init_event_stores/0)
    run_release_step(:migrate_repos, &migrate_repos!/0)
    run_release_step(:ensure_release_services_started, &ensure_release_services_started!/0)

    run_release_step(
      :await_system_group_backfill_source_projections,
      &await_system_group_backfill_source_projections!/0
    )

    run_release_step(:run_system_groups_backfill, &run_system_groups_backfill!/0)
    run_release_step(:ensure_production_smoke_fixtures, &ensure_production_smoke_fixtures!/0)
  end

  def verify_schema! do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &verify_repo_schema!/1)
    end
  end

  def reconcile_legacy_admin_history! do
    run_release_step(:load_app, &load_app/0)
    run_release_step(:ensure_release_services_started, &ensure_release_services_started!/0)

    report =
      Memba.Membership.AdminHistoryReconciliation.run!(admin_history_reconciliation_env_opts())

    IO.puts(Jason.encode!(report))
    report
  end

  def verify_source_backed_admin_invariant! do
    run_release_step(:load_app, &load_app/0)
    run_release_step(:ensure_release_services_started, &ensure_release_services_started!/0)

    verify_source_backed_admin_invariant!(source_backed_admin_invariant_env_opts())
  end

  def verify_repo_schema!(repo) do
    missing_tables = missing_tables(repo)
    missing_columns = missing_columns(repo)

    case {missing_tables, missing_columns} do
      {[], []} ->
        :ok

      _ ->
        raise """
        Database schema drift detected after migrations.

        Missing tables: #{format_list(missing_tables)}
        Missing columns: #{format_missing_columns(missing_columns)}

        The release migration command only applies pending migration versions; it cannot repair a table or column that drifted after a migration was recorded in schema_migrations.
        """
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @required_schema_modules [
    Memba.Accounts.SignInToken,
    Memba.Membership.EmailAddressVerificationToken,
    Memba.Membership.Projections.Club,
    Memba.Membership.Projections.Group,
    Memba.Membership.Projections.GroupMembership,
    Memba.Membership.Projections.MemberPermission,
    Memba.Membership.Projections.Membership,
    Memba.Membership.Projections.Person,
    Memba.Membership.Projections.Role,
    Memba.Membership.Projections.RoleAssignment,
    Memba.Membership.Projections.RolePermission,
    Memba.Messaging.Projections.ConversationGroupAccess,
    Memba.Messaging.Projections.EmailDelivery,
    Memba.Messaging.Projections.InboundEmailSource,
    Memba.Messaging.Projections.MemberEmailDelivery,
    Memba.Messaging.Projections.MembaStaffEmailDelivery,
    Memba.Messaging.Projections.Message
  ]

  @system_group_backfill_source_projectors [
    Memba.Membership.Projectors.Club,
    Memba.Membership.Projectors.Group,
    Memba.Membership.Projectors.GroupMembership,
    Memba.Membership.Projectors.Membership,
    Memba.Membership.Projectors.Role,
    Memba.Messaging.Projectors.ConversationGroupAccess,
    Memba.Messaging.Projectors.Message
  ]

  @required_manual_columns %{
    "projection_versions" => ~w(projection_name last_seen_event_number inserted_at updated_at)
  }

  defp missing_tables(repo) do
    existing =
      repo
      |> query!("""
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      """)
      |> MapSet.new(fn [table_name] -> table_name end)

    required_columns()
    |> Map.keys()
    |> Enum.sort()
    |> Enum.reject(&MapSet.member?(existing, &1))
  end

  defp missing_columns(repo) do
    required_columns()
    |> Enum.reduce([], fn {table_name, required_columns}, missing ->
      existing =
        repo
        |> query!(
          """
          SELECT column_name
          FROM information_schema.columns
          WHERE table_schema = 'public' AND table_name = $1
          """,
          [table_name]
        )
        |> MapSet.new(fn [column_name] -> column_name end)

      missing_for_table = Enum.reject(required_columns, &MapSet.member?(existing, &1))

      case missing_for_table do
        [] -> missing
        missing_for_table -> [{table_name, missing_for_table} | missing]
      end
    end)
    |> Enum.reverse()
  end

  defp required_columns do
    schema_columns =
      Map.new(@required_schema_modules, fn schema_module ->
        table_name = schema_module.__schema__(:source)

        columns =
          schema_module.__schema__(:fields)
          |> Enum.map(&schema_module.__schema__(:field_source, &1))
          |> Enum.map(&to_string/1)

        {table_name, columns}
      end)

    Map.merge(schema_columns, @required_manual_columns)
  end

  defp query!(repo, sql, params \\ []) do
    repo
    |> Ecto.Adapters.SQL.query!(sql, params)
    |> Map.fetch!(:rows)
  end

  defp format_list([]), do: "none"
  defp format_list(values), do: Enum.join(values, ", ")

  defp format_missing_columns([]), do: "none"

  defp format_missing_columns(missing_columns) do
    missing_columns
    |> Enum.map(fn {table_name, columns} -> "#{table_name}.#{Enum.join(columns, ",")}" end)
    |> Enum.join("; ")
  end

  defp migrate_repos! do
    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn repo ->
          migrated = Ecto.Migrator.run(repo, :up, all: true)
          verify_repo_schema!(repo)
          migrated
        end)
    end

    :ok
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp init_event_stores do
    @app
    |> Application.fetch_env!(:event_stores)
    |> Enum.each(fn event_store ->
      config = event_store.config()

      ensure_event_store_schema(config)
      EventStore.Tasks.Init.exec(config, quiet: true)
    end)
  end

  defp ensure_event_store_schema(config) do
    schema = Keyword.fetch!(config, :schema)

    {:ok, conn} =
      config
      |> EventStore.Config.default_postgrex_opts()
      |> Postgrex.start_link()

    Postgrex.query!(conn, ~s(CREATE SCHEMA IF NOT EXISTS "#{schema}"), [])

    true = Process.unlink(conn)
    true = Process.exit(conn, :shutdown)
  end

  defp ensure_release_services_started! do
    {:ok, _started} = Application.ensure_all_started(@app)
    :ok
  end

  defp verify_source_backed_admin_invariant!(opts) do
    report = Memba.Membership.SourceBackedAdminInvariant.check!(opts)

    IO.puts(Jason.encode!(report))
    report
  end

  defp await_system_group_backfill_source_projections! do
    timeout =
      Application.get_env(:memba, :system_groups_backfill_projection_barrier_timeout, 60_000)

    Memba.ProjectionBarrier.await!(@system_group_backfill_source_projectors, timeout: timeout)
    :ok
  end

  defp run_system_groups_backfill! do
    Memba.Membership.SystemGroups.Backfill.run!()
    :ok
  end

  defp ensure_production_smoke_fixtures! do
    Memba.ProductionSmokeFixtures.ensure!()
    :ok
  end

  defp admin_history_reconciliation_env_opts do
    mode = admin_history_mode(System.get_env("MEMBA_ADMIN_HISTORY_MODE"))

    [mode: mode]
    |> maybe_put_env_opt(:club_ids, admin_history_club_ids())
    |> maybe_put_env_opt(:operation_id, System.get_env("MEMBA_ADMIN_HISTORY_OPERATION_ID"))
    |> maybe_put_env_opt(
      :approval_reference,
      System.get_env("MEMBA_ADMIN_HISTORY_APPROVAL_REFERENCE")
    )
    |> maybe_put_env_opt(:acknowledgement, System.get_env("MEMBA_ADMIN_HISTORY_ACKNOWLEDGEMENT"))
  end

  defp admin_history_mode("apply"), do: :apply
  defp admin_history_mode("APPLY"), do: :apply
  defp admin_history_mode(_mode), do: :dry_run

  defp admin_history_club_ids do
    case System.get_env("MEMBA_ADMIN_HISTORY_CLUB_IDS") do
      nil ->
        []

      value ->
        value
        |> String.split([",", "\n"], trim: true)
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
    end
  end

  defp source_backed_admin_invariant_env_opts do
    []
    |> maybe_put_env_opt(:phase, System.get_env("MEMBA_ADMIN_INVARIANT_PHASE"))
  end

  defp maybe_put_env_opt(opts, _key, nil), do: opts
  defp maybe_put_env_opt(opts, _key, []), do: opts
  defp maybe_put_env_opt(opts, key, value), do: Keyword.put(opts, key, value)

  defp load_app do
    # Many platforms require SSL when connecting to the database.
    Application.ensure_all_started(:ssl)
    Application.ensure_all_started(:postgrex)
    Application.ensure_loaded(@app)
  end

  defp run_release_step(name, default) when is_atom(name) and is_function(default, 0) do
    case Keyword.get(release_step_overrides(), name) do
      nil -> default.()
      override when is_function(override, 0) -> override.()
    end
  end

  defp release_step_overrides do
    Application.get_env(@app, :release_step_overrides, [])
  end
end
