defmodule Memba.ReleaseAdminInvariantTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Memba.ReleaseAdminInvariant

  test "uses one bounded isolated connection and never starts the Memba application" do
    log = start_supervised!({Agent, fn -> [] end})
    pid = self()

    report = passing_report()

    output =
      capture_io(fn ->
        assert ^report =
                 ReleaseAdminInvariant.run!(
                   phase: "pre-deploy",
                   repo_config: [url: "ecto://not-printed"],
                   dependency_starter: fn -> record(log, :minimal_dependencies) end,
                   repo_starter: fn config ->
                     send(pid, {:repo_config, config})
                     record(log, :repo_started)
                     {:ok, self()}
                   end,
                   repo_stopper: fn _repo -> record(log, :repo_stopped) end,
                   checker: fn opts ->
                     assert opts[:repo] == Memba.ReleaseAdminInvariantRepo
                     record(log, :checked)
                     report
                   end
                 )
      end)

    assert_receive {:repo_config, config}
    assert config[:pool] == DBConnection.ConnectionPool
    assert config[:pool_size] == 1
    assert config[:pool_count] == 1
    assert config[:connect_timeout] == 10_000
    assert config[:timeout] == 60_000
    assert config[:queue_target] == 10_000
    assert config[:queue_interval] == 10_000

    assert Agent.get(log, & &1) == [
             :minimal_dependencies,
             :repo_started,
             :checked,
             :repo_stopped
           ]

    assert Jason.decode!(String.trim(output)) == report
    refute :full_memba_application_started in Agent.get(log, & &1)
  end

  test "the real dedicated Repo starts and shuts down without the application Repo" do
    refute Process.whereis(Memba.ReleaseAdminInvariantRepo)
    main_repo_pid = Process.whereis(Memba.Repo)
    report = passing_report()

    capture_io(fn ->
      assert ^report =
               ReleaseAdminInvariant.run!(
                 repo_config: Application.fetch_env!(:memba, Memba.Repo),
                 checker: fn opts ->
                   assert opts[:repo] == Memba.ReleaseAdminInvariantRepo
                   assert is_pid(Process.whereis(Memba.ReleaseAdminInvariantRepo))
                   assert Process.whereis(Memba.Repo) == main_repo_pid
                   report
                 end
               )
    end)

    refute Process.whereis(Memba.ReleaseAdminInvariantRepo)
    assert Process.whereis(Memba.Repo) == main_repo_pid
  end

  test "stops the isolated Repo and emits JSON before an invariant violation exits nonzero" do
    log = start_supervised!({Agent, fn -> [] end})
    report = violation_report()

    output =
      capture_io(fn ->
        assert_raise RuntimeError, ~r/invariant violations detected/, fn ->
          ReleaseAdminInvariant.run!(
            repo_config: [],
            dependency_starter: fn -> :ok end,
            repo_starter: fn _config -> {:ok, self()} end,
            repo_stopper: fn _repo -> record(log, :repo_stopped) end,
            checker: fn _opts -> report end
          )
        end
      end)

    assert Agent.get(log, & &1) == [:repo_stopped]
    assert Jason.decode!(String.trim(output)) == report
  end

  test "stops the isolated Repo and emits infrastructure JSON on a query failure" do
    log = start_supervised!({Agent, fn -> [] end})

    report = %{
      "pass" => false,
      "failure_kind" => "infrastructure_or_connection",
      "error" => %{"type" => "DBConnection.ConnectionError", "message" => "tcp recv: closed"}
    }

    output =
      capture_io(fn ->
        assert_raise RuntimeError, ~r/execution failed/, fn ->
          ReleaseAdminInvariant.run!(
            repo_config: [],
            dependency_starter: fn -> :ok end,
            repo_starter: fn _config -> {:ok, self()} end,
            repo_stopper: fn _repo -> record(log, :repo_stopped) end,
            checker: fn _opts -> report end
          )
        end
      end)

    assert Agent.get(log, & &1) == [:repo_stopped]
    assert Jason.decode!(String.trim(output)) == report
  end

  test "Repo startup failure emits redacted infrastructure evidence and exits nonzero" do
    output =
      capture_io(fn ->
        assert_raise RuntimeError, ~r/infrastructure\/connection failure/, fn ->
          ReleaseAdminInvariant.run!(
            phase: "post-deploy",
            repo_config: [password: "must-not-appear"],
            dependency_starter: fn -> :ok end,
            repo_starter: fn _config -> {:error, {:password, "must-not-appear"}} end
          )
        end
      end)

    refute output =~ "must-not-appear"
    report = Jason.decode!(String.trim(output))
    assert report["pass"] == false
    assert report["failure_kind"] == "infrastructure_or_connection"
    assert report["phase"] == "post-deploy"
  end

  defp passing_report do
    %{
      "pass" => true,
      "transaction_read_only" => "on",
      "event_store_columns" => [
        %{"column_name" => "data", "data_type" => "bytea"},
        %{"column_name" => "metadata", "data_type" => "bytea"}
      ],
      "checks" => %{
        "active_membership_source_facts" => %{"violation_count" => 0},
        "populated_club_complete_admin_source_backing" => %{"violation_count" => 0},
        "projected_admin_assignment_source_backing" => %{"violation_count" => 0}
      }
    }
  end

  defp violation_report do
    put_in(
      passing_report(),
      ["checks", "populated_club_complete_admin_source_backing"],
      %{"violation_count" => 1, "violations" => [%{"club_id" => "clb_example"}]}
    )
    |> Map.put("pass", false)
  end

  defp record(log, event), do: Agent.update(log, &(&1 ++ [event]))
end
