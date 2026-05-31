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
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
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
