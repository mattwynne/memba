The dev check failure is a sandbox/runtime blocker; no code, configuration, dependency, or test changes are required.

A stale acceptance Phoenix server remains alive and holds exactly 24 idle connections to `memba_test`, matching PostgreSQL’s error:

- Shell PID `79820`: `mix phx.server`
- BEAM PID `79834`: named `memba_acceptance_server`
- PostgreSQL backend PIDs `79901`–`79925`: 24 idle `memba_test` sessions
- Server working directory: `/repos/mattwynne/memba/web`

This is residue from the earlier timed-out acceptance run. Per the sandbox/runtime boundary, I did not terminate managed processes, restart PostgreSQL, or alter application/test code to compensate.

### Failure-to-fix mapping

| Dev check failure | Cause | Change made | Files |
|---|---|---|---|
| `ERROR 55006 (object_in_use): database "memba_test" is being accessed by other users` | Orphaned acceptance server retaining a 24-connection database pool | None; requires sandbox-managed process cleanup or restart | None |
| Dependency advisories shown in output | Informational audit output; execution continued past this section and failed later during database reset | None; unrelated to iteration 059 and reported dependencies are already resolved as far as the lockfile permits | None |

### Existing review repair

The previously applied repair remains present in [send_test.exs](/workspace/memba/web/test/memba_web/live/member_invitation_live/send_test.exs:214): `club_host/2` now explicitly requires the expected projected `Club` instead of silently falling back to fixture data. I made no further edits.

Current `HEAD` is `f0253d26c552990148ed4b78fd9fb48f58c148cf`. The only working-tree entry is the pipeline-generated untracked `.fabro/tmp/` directory.

### Validation

- Corrected targeted formatter check for `send_test.exs`: passed.
- `git diff --check`: passed.
- Full `dev ci`: not rerun because it cannot drop `memba_test` while the stale server owns those sessions.
- No tests were weakened, skipped, or modified.
- No acceptance feature files were changed.
- No commits were created.

The remaining operational step is for the sandbox owner to stop the orphaned acceptance server or restart the sandbox-managed PostgreSQL/process state, then rerun:

```bash
PATH="$PWD/bin:$PATH" dev ci
```

Until that runtime state is cleaned up, a conclusive full-suite result on the current revision is blocked.