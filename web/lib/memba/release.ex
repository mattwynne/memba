defmodule Memba.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :memba

  def migrate do
    load_app()
    init_event_stores()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn repo ->
          migrated = Ecto.Migrator.run(repo, :up, all: true)
          verify_repo_schema!(repo)
          migrated
        end)
    end
  end

  def verify_schema! do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &verify_repo_schema!/1)
    end
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
    Memba.Membership.Projections.Club,
    Memba.Membership.Projections.Membership,
    Memba.Membership.Projections.Person,
    Memba.Messaging.Projections.EmailDelivery,
    Memba.Messaging.Projections.MemberEmailDelivery,
    Memba.Messaging.Projections.MembaStaffEmailDelivery,
    Memba.Messaging.Projections.Message
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

  defp load_app do
    # Many platforms require SSL when connecting to the database.
    Application.ensure_all_started(:ssl)
    Application.ensure_all_started(:postgrex)
    Application.ensure_loaded(@app)
  end
end
