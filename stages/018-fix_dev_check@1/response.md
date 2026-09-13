The implementation does not require a code or test repair. `dev check` is blocked by an orphaned Phoenix acceptance server from the earlier timed-out run, so I stopped at the sandbox/runtime boundary as required.

### Failure-to-fix mapping

| Dev check failure | Diagnosis | Code/config/test fix |
| --- | --- | --- |
| `memba_test` could not be dropped because 28 sessions were connected | An orphaned `mix phx.server` process is still maintaining 28 idle Ecto/EventStore connections | None. This is sandbox process cleanup, not an application defect |
| Dependency security advisories appeared in output | Informational output from dependency resolution; it continued with “All dependencies are up to date” | None within iteration 061 |

The orphaned process was confirmed as:

- PID `96593`: `bash ... mix phx.server`, parent PID 1
- PID `96610`: `beam.smp`, child of 96593, running as `memba_acceptance_server`
- Both are rooted in `/repos/mattwynne/memba/web`.
- PostgreSQL reports exactly 28 `memba_test` sessions started by that server.
- The process manager reports only PostgreSQL as managed, so this Phoenix server is outside the current managed lifecycle.

The quality gate reaches `precommit` before acceptance, as shown in [bin/dev](/workspace/memba/bin/dev:786), and fails during the database reset before any relevant test failure is produced. The captured failure is in [.fabro/tmp/dev-check.log](/workspace/memba/.fabro/tmp/dev-check.log).

### Changes made

No files were changed. In particular, I did not modify:

- Product code or configuration
- Dependencies
- Tests or locked acceptance features
- `bin/dev` or database lifecycle scripts

The existing manual desktop/mobile validation remains recorded in [manual-browser-validation.md](/workspace/memba/docs/iterations/061-discover-club-groups/manual-browser-validation.md:1), including the passing four-scenario browser matrix.

### Validation

No fresh test suite was started after confirming the live orphan, because it would deterministically fail at the same database-drop step.

Existing evidence remains:

- Responsive browser validation: 4 scenarios passed, 40 steps passed.
- An earlier pipeline full `dev check` passed before the documentation-only validation record.
- The latest two exact-state attempts were blocked by the orphaned runtime sessions, not by test assertions.

### Remaining blocker

The sandbox/runtime owner needs to terminate or reap orphaned acceptance server PIDs `96593` and `96610`, or restart the sandbox, then rerun:

```sh
env -u MEMBA_DEVENV_SHELL ./bin/dev check
```

Until that runtime cleanup occurs, the current HEAD cannot be certified with a fresh passing `dev check`. The worktree has no tracked or staged changes; the only untracked files are the pre-existing `.fabro/tmp/` validation and workflow artifacts.