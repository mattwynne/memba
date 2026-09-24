defmodule Memba.ReleaseAdminInvariant do
  @moduledoc """
  Runs the production Admin invariant from a release eval without starting Memba.

  The eval VM starts only the database client dependencies and a dedicated,
  single-connection Repo. The Repo is stopped before the report is validated so
  success, invariant violations, and query failures all release the connection.
  """

  alias Memba.Membership.SourceBackedAdminInvariant
  alias Memba.ReleaseAdminInvariantRepo

  @connect_timeout 10_000
  @query_timeout 60_000
  @shutdown_timeout 5_000

  @spec run!(keyword()) :: map()
  def run!(opts \\ []) when is_list(opts) do
    dependency_starter = Keyword.get(opts, :dependency_starter, &start_dependencies!/0)
    repo_starter = Keyword.get(opts, :repo_starter, &ReleaseAdminInvariantRepo.start_link/1)
    repo_stopper = Keyword.get(opts, :repo_stopper, &stop_repo!/1)
    checker = Keyword.get(opts, :checker, &SourceBackedAdminInvariant.check/1)
    validator = Keyword.get(opts, :validator, &SourceBackedAdminInvariant.validate!/1)
    repo = Keyword.get(opts, :repo, ReleaseAdminInvariantRepo)
    check_opts = Keyword.take(opts, [:phase]) |> Keyword.put(:repo, repo)

    dependency_starter.()

    case repo_starter.(isolated_repo_config(opts)) do
      {:ok, repo_pid} ->
        report =
          try do
            checker.(check_opts)
          after
            repo_stopper.(repo_pid)
          end

        IO.puts(Jason.encode!(report))
        validator.(report)

      {:error, _reason} ->
        report = infrastructure_report(opts[:phase])
        IO.puts(Jason.encode!(report))

        raise RuntimeError,
              "source-backed Admin invariant infrastructure/connection failure: isolated Repo failed to start"
    end
  end

  @doc false
  def isolated_repo_config(opts \\ []) do
    base_config =
      Keyword.get_lazy(opts, :repo_config, fn ->
        Application.fetch_env!(:memba, Memba.Repo)
      end)

    Keyword.merge(base_config,
      pool: DBConnection.ConnectionPool,
      pool_size: 1,
      pool_count: 1,
      connect_timeout: @connect_timeout,
      timeout: @query_timeout,
      queue_target: @connect_timeout,
      queue_interval: @connect_timeout
    )
  end

  defp start_dependencies! do
    Application.ensure_loaded(:memba)

    Enum.each([:ssl, :postgrex, :ecto_sql], fn application ->
      case Application.ensure_all_started(application) do
        {:ok, _started} -> :ok
        {:error, reason} -> raise "could not start #{application}: #{inspect(reason)}"
      end
    end)
  end

  defp stop_repo!(repo_pid) do
    Supervisor.stop(repo_pid, :normal, @shutdown_timeout)
  end

  defp infrastructure_report(phase) do
    %{
      "pass" => false,
      "failure_kind" => "infrastructure_or_connection",
      "error" => %{
        "type" => "repo_start_error",
        "message" => "isolated Repo failed to start"
      }
    }
    |> maybe_put_phase(phase)
  end

  defp maybe_put_phase(report, nil), do: report
  defp maybe_put_phase(report, ""), do: report
  defp maybe_put_phase(report, phase), do: Map.put(report, "phase", phase)
end
