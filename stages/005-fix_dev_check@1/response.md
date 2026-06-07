Full automated suite is passing now. No tracked code/config/test changes were needed.

## Failure-to-fix mapping

| Preceding dev check failure | What I found / did | Files/modules involved |
|---|---|---|
| 52 ExUnit failures in `Memba.Membership.QueryTest`, all failing in `Memba.EventSourcedCase.stop_event_sourced_projectors!/0` because `Memba.Supervisor` was not alive | Could not reproduce. Re-ran Mix quality gate and the full ExUnit suite passed repeatedly with 585 tests / 0 failures. No product-code or test change was needed. | Inspected `web/test/support/event_sourced_case.ex`, `web/lib/memba/application.ex`, `web/test/memba/membership/query_test.exs` |
| Acceptance failure: `sh: line 1: cucumber-js: command not found` | Acceptance npm dependencies were not installed. Installed them inside the devenv shell with `devenv shell -- bash -lc 'cd acceptance-tests && npm ci'`. This creates ignored `acceptance-tests/node_modules/`; no tracked files changed. | `acceptance-tests/package.json`, `acceptance-tests/package-lock.json` define the dependency; ignored runtime artifact `acceptance-tests/node_modules/` installed |

## Files changed

No tracked files changed.

Current tracked working tree remains clean except for the existing workflow temp dir:

```text
?? .fabro/tmp/
```

## Validation run

- `PATH="$PWD/bin:$PATH" dev check --quick`
  - Passed: `585 tests, 0 failures`

- `PATH="$PWD/bin:$PATH" dev ci` before installing npm deps
  - ExUnit passed: `585 tests, 0 failures`
  - Acceptance failed: `cucumber-js: command not found`

- `devenv shell -- bash -lc 'cd acceptance-tests && npm ci'`
  - Passed: installed 119 npm packages, 0 vulnerabilities

- `PATH="$PWD/bin:$PATH" dev ci`
  - Passed ExUnit: `585 tests, 0 failures`
  - Passed acceptance: `44 scenarios (44 passed)`, `291 steps (291 passed)`

## Remaining failures / questions

None. The full `dev ci` quality gate now passes.