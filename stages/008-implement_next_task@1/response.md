Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `001 Inspect current Staff club/person routes and forms, especially any club-scoped create-person/add-member path and /admin/clubs/:club_id/people/:person_id/edit`.

2. **Changes made**
   - Added inspection notes at:
     - `docs/iterations/028-staff-member-invitations/staff-club-person-route-inspection.md`
   - Documented:
     - Current Staff `/admin` club/person routes.
     - Current direct `New person` + `Add member` bypass path.
     - Existing `/admin/clubs/:club_id/people/:person_id/edit` behaviour to preserve.
     - Tests and acceptance helpers likely affected by later invitation/decommissioning tasks.
   - Checked off only the selected todo line in:
     - `docs/iterations/028-staff-member-invitations/todo.md`

3. **Focused validation**
   - Ran route inspection:
     - `PATH="$PWD/bin:$PATH" bin/mix phx.routes | grep -E "admin.*clubs|auth/onboard|auth/sign-in"`
     - Result: passed; confirmed current Staff club/person routes.
   - Ran focused LiveView tests in a clean devenv shell due stale inherited `PGHOST`/`PGPORT` in the Fabro shell:
     - `env -u DEVENV_DOTFILE -u DEVENV_PROFILE -u DEVENV_ROOT -u DEVENV_STATE -u DEVENV_TASKS -u DEVENV_TASK_FILE -u PGDATA -u PGHOST -u PGPORT PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/admin_people_live_test.exs test/memba_web/live/admin/clubs_live/show_test.exs`
     - Result: passed — `15 tests, 0 failures`.
   - Direct `bin/mix test ...` attempts before the clean shell failed because Postgres was started under a different socket path than the inherited `PGHOST`; the clean-shell run passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 001 Inspect current Staff club/person routes and forms, especially any club-scoped create-person/add-member path and /admin/clubs/:club_id/people/:person_id/edit.`
   - To:
     - `- [x] 001 Inspect current Staff club/person routes and forms, especially any club-scoped create-person/add-member path and /admin/clubs/:club_id/people/:person_id/edit.`

5. **Todo splits/additions/reordering**
   - No todo splits, additions, or reordering.
   - Added only a durable inspection note for the selected task.

6. **ADR conformance evidence**
   - Read relevant ADRs:
     - ADR 0001 Phoenix core application.
     - ADR 0015 LiveView default for app surfaces.
     - ADR 0013 PhoenixTest for feature-style web tests.
     - ADR 0022 projection barriers/read-your-writes context.
   - This task changed docs/todo only and preserves those constraints. The inspected routes are Phoenix LiveViews, and the focused validation used existing Phoenix/LiveView tests.