defmodule Memba.DevPrecommitContractTest do
  use ExUnit.Case, async: true

  @dev_script Path.expand("../../../bin/dev", __DIR__)

  test "planning structural check failure cannot be masked by a later successful command" do
    root =
      Path.join(System.tmp_dir!(), "memba-dev-precommit-#{System.unique_integer([:positive])}")

    bin = Path.join(root, "bin")
    marker = Path.join(root, "mix-called")
    File.mkdir_p!(Path.join(root, "web"))
    File.mkdir_p!(bin)

    File.write!(Path.join(bin, "python3"), "#!/usr/bin/env bash\nexit 37\n")

    File.write!(Path.join(bin, "mix"), """
    #!/usr/bin/env bash
    touch "$MIX_MARKER"
    exit 0
    """)

    Enum.each(["python3", "mix"], fn command ->
      File.chmod!(Path.join(bin, command), 0o755)
    end)

    on_exit(fn -> File.rm_rf!(root) end)

    dev_source = File.read!(@dev_script)

    assert [precommit_function] = Regex.run(~r/^_precommit\(\) \{\n.*?^\}/ms, dev_source)

    harness = """
    set +e
    repo_root="$TEST_ROOT"
    local_test_email_env() { "$@"; }
    #{precommit_function}
    _precommit
    status=$?
    printf 'status=%s\n' "$status"
    test "$status" -eq 37 || exit 90
    test ! -e "$MIX_MARKER" || exit 91
    """

    path = "#{bin}:#{System.fetch_env!("PATH")}"

    {output, status} =
      System.cmd("bash", ["-c", harness],
        env: [{"PATH", path}, {"TEST_ROOT", root}, {"MIX_MARKER", marker}],
        stderr_to_stdout: true
      )

    assert status == 0, output
    assert output =~ "status=37"
    refute File.exists?(marker)
  end
end
