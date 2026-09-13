`dev check` is blocked by stale sandbox runtime state; no code, configuration, dependency, or test changes are warranted.

### Failure-to-fix mapping

| Dev check output | Diagnosis | Required change |
| --- | --- | --- |
| PostgreSQL could not drop `memba_test` because 28 sessions remain connected | An orphaned acceptance Phoenix server is holding exactly 28 idle database connections | Sandbox process cleanup; no repository change |
| Dependency security advisories | Informational/non-blocking in this run—the check continued through dependency setup to the database reset | None within iteration 061 |

The orphaned processes are still alive:

- PID `96593`: `bash ... mix phx.server`, reparented to PID 1
- PID `96610`: its `beam.smp` child, running as `memba_acceptance_server`
- PostgreSQL itself is healthy and managed, reporting phase `ready`
- PostgreSQL confirms `28` idle connections to `memba_test`

Per the sandbox/runtime boundary, I did not terminate these processes, alter database lifecycle behavior, or patch product/test code to work around them.

Files changed:

- None.
- The tracked and staged diffs are empty.
- `.fabro/tmp/` contains only untracked workflow logs, screenshots, and temporary validation artifacts, including [dev-check.log](/workspace/memba/.fabro/tmp/dev-check.log).

Validation performed:

- Confirmed both orphaned process IDs remain active.
- Confirmed the 28 idle `memba_test` connections.
- Confirmed managed PostgreSQL is ready.
- Confirmed `git diff --check`, tracked diff, and staged diff are clean.
- I did not start another test run because it would deterministically fail at the same database-drop step.

Remaining blocker: the sandbox owner must terminate/reap PIDs `96593` and `96610`, or restart the sandbox, then rerun:

```sh
env -u MEMBA_DEVENV_SHELL ./bin/dev check
```

Until that runtime cleanup occurs, the current HEAD cannot be certified as passing `dev check`.