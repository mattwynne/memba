Implemented a scoped test-runtime fix for the consistency timeout.

### Failure-to-fix mapping

| Dev check failure | Cause | Fix |
|---|---|---|
| `MembaWeb.DevTestSupportControllerTest` timed out creating a club with strong consistency | The sandbox exposes only one online BEAM scheduler, so the test Repo pool was calculated as two connections. The reset request and Club projector retained those connections under SQL Sandbox ownership, leaving the Group and Role projectors unable to acknowledge club events before Commanded’s five-second timeout. | [web/config/test.exs](/workspace/memba/web/config/test.exs:17) now retains scheduler-based sizing but enforces a 16-connection minimum for the test Repo pool. |

No product code or acceptance feature files were changed.

### Validation

- Exact failing test: 6 tests, 0 failures, 5 excluded.
- Complete `dev_test_support_controller_test.exs`: 6 tests, 0 failures.
- `dev check --quick`: passed with 1,129 tests, 0 failures, including formatting and static checks.
- `dev acceptance`: exited successfully with all browser scenarios passing.
- Combined `dev check`: reached the final acceptance cleanup, but the terminal wrapper exceeded its hard 600-second limit before returning an exit status. Its precommit and acceptance portions were subsequently run independently and both returned exit code 0.
- `git diff --check`: passed.

One tracked file is modified: [web/config/test.exs](/workspace/memba/web/config/test.exs:17). The pre-existing `.fabro/tmp/review-start-sha.txt` remains untracked and untouched.

There are no remaining test failures or human questions. The quality-gate output still includes non-failing dependency advisory notices and occasional background-projector SQL Sandbox ownership logs during ExUnit teardown; those pre-existing health signals are outside this iteration-scoped fix.