1. **Selected todo line**
   - `002 Inspect current Membership club command/event/aggregate/projector/projection code, public club route code, admin/staff route code, and all club creation call sites.`

2. **Changes made**
   - Added inspection artifact:
     - `docs/iterations/015-club-slugs/task-002-inspection.md`
   - The inspection documents:
     - current Membership club command/event/aggregate/router code;
     - club projection schema/projector/migration;
     - public Membership query API;
     - public `club_id` routing and host-handling state;
     - staff/admin club LiveView state;
     - all discovered club creation/direct projection insertion call sites to update in later tasks;
     - current `@wip` acceptance feature state.
   - No application code, tests, config, or acceptance feature files were changed.

3. **Focused validation commands run**
   - `git log --oneline --decorate -20` — inspected recent Fabro checkpoint context.
   - `git status --short` — confirmed clean tree before editing.
   - Targeted inspection commands with `find`, `grep`, and file reads for relevant Membership/web/test files.
   - `git diff --check` — passed with no whitespace errors.
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `257 tests, 0 failures`
     - Command exited successfully.

4. **Todo check-off made**
   - Changed exactly this ordinary todo line:
     ```md
     - [x] 002 Inspect current Membership club command/event/aggregate/projector/projection code, public club route code, admin/staff route code, and all club creation call sites.
     ```

5. **Todo splits/additions/reordering**
   - None. The selected task was completed as an inspection task and checked off directly.

6. **ADR conformance evidence**
   - Read and applied relevant accepted ADRs:
     - ADR 0002: Membership club behaviour remains understood as Commanded command/aggregate/event flow.
     - ADR 0007: later slug lookup should stay behind Membership public query APIs.
     - ADR 0008: tests use persistent EventStore/projection reset paths.
     - ADR 0009: projections use `commanded_ecto_projections`.
     - ADR 0011: `club_id` remains caller-generated UUID aggregate identity; slug is an attribute/addressing key.
     - ADR 0013: later staff/admin web behaviour should use PhoenixTest-style coverage.
     - ADR 0014: host-routing notes account for Fly.io production host/subdomain constraints.
     - ADR 0015: member application route notes preserve LiveView-by-default member surfaces.