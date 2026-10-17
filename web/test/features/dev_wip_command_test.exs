defmodule Memba.DevWipCommandTest do
  use ExUnit.Case, async: true

  setup do
    fixture =
      Path.join(
        System.tmp_dir!(),
        "memba-dev-wip-#{System.unique_integer([:positive, :monotonic])}"
      )

    bin_dir = Path.join(fixture, "bin")
    stub_dir = Path.join(fixture, "stubs")
    File.mkdir_p!(Path.join(fixture, "web"))
    File.mkdir_p!(bin_dir)
    File.mkdir_p!(stub_dir)

    dev = Path.join(bin_dir, "dev")
    File.cp!(Path.expand("../../../bin/dev", __DIR__), dev)
    File.chmod!(dev, 0o755)

    write_executable!(Path.join(bin_dir, "mix"), """
    #!/usr/bin/env bash
    printf '%s\n' "${FAKE_MIX_OUTPUT:-}"
    printf '%s|%s\n' "${MEMBA_WIP_TEST:-}" "$*" > "${FAKE_MIX_ARGS_FILE}"
    exit "${FAKE_MIX_STATUS:-0}"
    """)

    write_executable!(Path.join(stub_dir, "argc"), """
    #!/usr/bin/env bash
    exit 0
    """)

    write_executable!(Path.join(stub_dir, "devenv"), """
    #!/usr/bin/env bash
    if [[ "$*" == *"processes status postgres"* ]]; then
      echo "Phase: ready"
    fi
    """)

    on_exit(fn -> File.rm_rf!(fixture) end)

    {:ok, fixture: fixture, dev: dev, stub_dir: stub_dir}
  end

  test "no WIP fails without the passing-scenario message", context do
    {output, status, _args} = run_dev(context, ["test:wip"], 1, "found none")

    assert status == 1
    assert output =~ "found none"
    refute output =~ "This scenario now passes"
  end

  test "multiple WIP scenarios fail without executing a green transition", context do
    {output, status, _args} = run_dev(context, ["test:wip"], 1, "found 2: First WIP, Second WIP")

    assert status == 1
    assert output =~ "found 2: First WIP, Second WIP"
    refute output =~ "This scenario now passes"
  end

  test "a red WIP preserves the real test failure and status", context do
    {output, status, args} = run_dev(context, ["test:wip"], 7, "Assertion with == failed")

    assert status == 7
    assert output =~ "Assertion with == failed"
    refute output =~ "This scenario now passes"
    assert args == "1|test test/features/domain_cucumber_wip_test.exs --trace"
  end

  test "a green WIP preserves passing output but fails with the tag-removal message", context do
    {output, status, args} = run_dev(context, ["test:wip"], 0, "1 test, 0 failures")

    assert status == 1
    assert output =~ "1 test, 0 failures"
    assert output =~ "This scenario now passes. Remove its @wip tag."
    assert args == "1|test test/features/domain_cucumber_wip_test.exs --trace"
  end

  test "ordinary dev test keeps its existing arguments and success status", context do
    {output, status, args} =
      run_dev(context, ["test", "test/example_test.exs", "--trace"], 0, "ordinary pass")

    assert status == 0
    assert output =~ "ordinary pass"
    refute output =~ "Remove its @wip tag"
    assert args == "|test test/example_test.exs --trace"
  end

  defp run_dev(context, arguments, mix_status, mix_output) do
    args_file = Path.join(context.fixture, "mix-args")

    {output, status} =
      System.cmd(context.dev, arguments,
        env: [
          {"DEVENV_ROOT", context.fixture},
          {"FAKE_MIX_ARGS_FILE", args_file},
          {"FAKE_MIX_OUTPUT", mix_output},
          {"FAKE_MIX_STATUS", Integer.to_string(mix_status)},
          {"MEMBA_DEVENV_SHELL", "1"},
          {"MEMBA_DEV_SETUP_DONE", "1"},
          {"MEMBA_POSTGRES_PORT",
           Integer.to_string(20_000 + rem(System.unique_integer([:positive]), 20_000))},
          {"PATH", context.stub_dir <> ":" <> System.fetch_env!("PATH")}
        ],
        stderr_to_stdout: true
      )

    {output, status, args_file |> File.read!() |> String.trim()}
  end

  defp write_executable!(path, contents) do
    File.write!(path, contents)
    File.chmod!(path, 0o755)
  end
end
