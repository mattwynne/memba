defmodule Memba.ProductionAdminInvariantScriptTest do
  use ExUnit.Case, async: true

  @script Path.expand("../../../bin/verify-production-admin-invariant", __DIR__)

  setup do
    root =
      Path.join(System.tmp_dir!(), "memba-invariant-script-#{System.unique_integer([:positive])}")

    bin = Path.join(root, "bin")
    artifacts = Path.join(root, "artifacts")
    File.mkdir_p!(bin)

    flyctl = Path.join(bin, "flyctl")

    File.write!(flyctl, """
    #!/usr/bin/env bash
    printf '%s\n' "$*" > "$FAKE_FLY_ARGS"
    if [ "${FAKE_OLD_RELEASE_CONTRACT:-0}" = 1 ]; then
      [[ "$*" == *"Memba.Membership.SourceBackedAdminInvariant.check!"* ]] || exit 90
      [[ "$*" == *"Memba.Repo.start_link"* ]] || exit 91
      [[ "$*" != *"Memba.ReleaseAdminInvariant"* ]] || exit 92
      [[ "$*" != *"Memba.Release.verify_source_backed_admin_invariant"* ]] || exit 93
      [[ "$*" != *"Application.ensure_all_started(:memba)"* ]] || exit 94
    fi
    if [ "${FAKE_FLY_SLEEP:-0}" != 0 ]; then sleep "$FAKE_FLY_SLEEP"; fi
    printf '%s\n' '{"pass":true,"transaction_read_only":"on"}'
    exit "${FAKE_FLY_STATUS:-0}"
    """)

    real_tee = System.find_executable("tee")

    File.write!(Path.join(bin, "tee"), """
    #!/usr/bin/env bash
    #{real_tee} "$@"
    real_status=$?
    if [ -n "${FAKE_TEE_STATUS:-}" ]; then exit "$FAKE_TEE_STATUS"; fi
    exit "$real_status"
    """)

    Enum.each([flyctl, Path.join(bin, "tee")], &File.chmod!(&1, 0o755))

    on_exit(fn -> File.rm_rf!(root) end)

    {:ok, root: root, bin: bin, artifacts: artifacts}
  end

  test "old-release-compatible eval is self-contained and never starts the Memba application",
       context do
    args_file = Path.join(context.root, "args")

    {output, 0} =
      run_script(context, "pre-deploy", args_file,
        MEMBA_ADMIN_INVARIANT_ATTEMPTS: "1",
        FAKE_OLD_RELEASE_CONTRACT: "1"
      )

    args = File.read!(args_file)
    assert args =~ "/app/bin/memba eval"
    assert args =~ "Application.ensure_loaded(:memba)"
    assert args =~ "Application.ensure_all_started(application)"
    assert args =~ "[:ssl, :postgrex, :ecto_sql]"
    assert args =~ "Memba.Repo.start_link(repo_config)"
    assert args =~ "Memba.Membership.SourceBackedAdminInvariant.check!(phase: \"pre-deploy\")"
    refute args =~ "Application.ensure_all_started(:memba)"
    refute args =~ "Memba.ReleaseAdminInvariant"
    refute args =~ "Memba.Release.verify_source_backed_admin_invariant"
    refute args =~ " rpc "

    evidence = File.read!(Path.join(context.artifacts, "pre-deploy-attempt-1.txt"))
    assert evidence =~ ~s({"pass":true,"transaction_read_only":"on"})
    assert output =~ "phase=pre-deploy attempt=1/1"
  end

  test "composes isolated pool, remote timeout, bounded query settings, and cleanup", context do
    args_file = Path.join(context.root, "args")

    {_output, 0} =
      run_script(context, "post-deploy", args_file,
        MEMBA_ADMIN_INVARIANT_ATTEMPTS: "1",
        MEMBA_ADMIN_INVARIANT_ATTEMPT_TIMEOUT_SECONDS: "20",
        MEMBA_ADMIN_INVARIANT_REMOTE_TIMEOUT_SECONDS: "15"
      )

    args = File.read!(args_file)
    assert args =~ "timeout --signal=TERM --kill-after=10s 15s /app/bin/memba eval"
    assert args =~ "pool_size: 1"
    assert args =~ "pool_count: 1"
    assert args =~ "connect_timeout: 10_000"
    assert args =~ "timeout: 60_000"
    assert args =~ "try do"
    assert args =~ "after"
    assert args =~ "Supervisor.stop(repo, :normal, 5_000)"
  end

  test "a nonzero eval remains blocking and retains evidence", context do
    args_file = Path.join(context.root, "args")

    {output, status} =
      run_script(context, "post-deploy", args_file,
        MEMBA_ADMIN_INVARIANT_ATTEMPTS: "1",
        FAKE_FLY_STATUS: "42"
      )

    assert status == 1
    assert output =~ "Invariant eval exited nonzero (status=42)"
    assert output =~ "failed after 1 attempts"

    evidence = File.read!(Path.join(context.artifacts, "post-deploy-attempt-1.txt"))
    assert evidence =~ ~s({"pass":true)
    assert evidence =~ "status=42"
  end

  test "an outer timeout blocks a wedged SSH command and leaves diagnostic evidence", context do
    args_file = Path.join(context.root, "args")

    {output, status} =
      run_script(context, "pre-deploy", args_file,
        MEMBA_ADMIN_INVARIANT_ATTEMPTS: "1",
        MEMBA_ADMIN_INVARIANT_ATTEMPT_TIMEOUT_SECONDS: "2",
        MEMBA_ADMIN_INVARIANT_REMOTE_TIMEOUT_SECONDS: "1",
        FAKE_FLY_SLEEP: "5"
      )

    assert status == 1
    assert output =~ "infrastructure failure"
    assert output =~ "timeout"

    evidence = File.read!(Path.join(context.artifacts, "pre-deploy-attempt-1.txt"))
    assert evidence =~ "infrastructure failure"
  end

  test "an artifact write failure blocks even when flyctl succeeds", context do
    args_file = Path.join(context.root, "args")

    {output, status} =
      run_script(context, "post-deploy", args_file,
        MEMBA_ADMIN_INVARIANT_ATTEMPTS: "1",
        FAKE_TEE_STATUS: "73"
      )

    assert status == 1
    assert output =~ "evidence artifact write failed (tee status=73)"
    assert output =~ "blocking deployment"
  end

  defp run_script(context, phase, args_file, extra_env) do
    env =
      [
        {"PATH", context.bin <> ":" <> System.get_env("PATH")},
        {"FAKE_FLY_ARGS", args_file}
      ] ++ Enum.map(extra_env, fn {key, value} -> {to_string(key), value} end)

    System.cmd(@script, [phase, context.artifacts], env: env, stderr_to_stdout: true)
  end
end
