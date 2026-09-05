# Problem: dev ci masked a failing precommit behind passing browser acceptance

Date: 2026-09-05

## Observation

The guarded iteration 057 implementation run `01M1RA4HRSTJZNXNDGSGVY4XY8` reached its `Run Dev Check` node and Fabro recorded that node as succeeded. The command output contained contradictory evidence:

- `mix precommit`: 1,129 tests, 1 failure;
- browser acceptance: 122 scenarios and 877 steps passed;
- `bin/dev ci`: exit status 0.

The failing test was `MembaWeb.DevTestSupportControllerTest` (`POST /dev/test-support/reset clears event-sourced server state for fixed identities`): `Membership.create_person/2` returned `{:error, :consistency_timeout}`. Because the command returned success, the workflow published iteration 057 and marked it merged instead of routing through `fix_dev_check`.

## Resolution

Date: 2026-09-05

Root cause: `with_quality_gate_lock` deliberately executes its callback while `set +e` is active so it can capture the callback status and release the quality-gate lock. Bash therefore did not stop the composite `_ci` function when `precommit` failed. `_ci` continued into browser acceptance and returned the status of that final successful command. `_check` had the same latent false-green path. The problem was exit-code composition in `bin/dev`, not Fabro's interpretation of the command node.

Fix applied:

- `bin/dev`: `_ci` and `_check` now explicitly return immediately when service startup, setup, or precommit fails. Browser acceptance cannot overwrite an earlier failure status.
- `.fabro/workflows/scripts/test_dev_quality_gate_exit_status.sh`: loads the real helper functions with controlled doubles and proves both composite gates preserve a precommit status of 23, skip acceptance after failure, and still run acceptance after success.

Validation:

- The new regression failed before the fix: `_ci` continued after the simulated precommit failure and returned success.
- `bash .fabro/workflows/scripts/test_dev_quality_gate_exit_status.sh` — passed after the fix.
- `bash -n bin/dev .fabro/workflows/scripts/test_dev_quality_gate_exit_status.sh` — passed.
- `env -u MEMBA_DEVENV_SHELL ./bin/dev test test/memba_web/controllers/dev_test_support_controller_test.exs --repeat-until-failure 20` — 21 consecutive executions / 126 tests passed, so the single published-run consistency timeout was not reproduced in isolation and no speculative timeout increase was made.
- `env -u MEMBA_DEVENV_SHELL ./bin/dev check` — 1,129 tests with 0 failures; 122 browser scenarios and 877 steps passed.
- Independent Codex review — approved with no blockers.

Remaining follow-up:

- If the reset regression's consistency timeout recurs, investigate it under full-suite load rather than increasing the timeout speculatively.
- Complete the independent review of already-published iteration 057.
