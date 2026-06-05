Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `014 Update or add LiveView tests for:`

2. **Changes made**
   - Updated `web/test/memba_web/live/admin_operations_index_live_test.exs`
     - Added live-rendered staff navigation coverage proving the staff nav exposes only:
       - Clubs
       - People
       - Messages
       - Deliveries
     - Added assertions that Incoming and Roles are absent.
     - Added a small selector-count helper for exact nav link count.
   - Updated `web/test/memba_web/live/admin/clubs_live/show_test.exs`
     - Added direct LiveView coverage for adding an existing person as a club member.
     - Asserts the person appears in People, is absent from Members before submit, appears in Members after submit, flashes “Member added”, and the membership query confirms the person is active in the club.
   - Confirmed existing tests already cover:
     - `/admin/people` read-only list and multi-club membership summary.
     - `/admin/messages` read-only list and diagnostics links.
     - Absence of staff-side send-message affordance.
     - Existing club/person/member removal workflows.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/live/admin_operations_index_live_test.exs test/memba_web/live/admin/clubs_live/show_test.exs`
     - Passed after applying formatter-requested wrapping.
   - `PATH="$PWD/bin:$PATH" bin/mix test ...`
     - Did not run tests due to sandbox Postgres readiness path mismatch.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && mix test test/memba_web/live/admin_operations_index_live_test.exs test/memba_web/live/admin/clubs_live/show_test.exs test/memba_web/live/admin_people_live_test.exs test/memba_web/live/admin_diagnostics_live_test.exs'`
     - Passed: `23 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `526 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 014 Update or add LiveView tests for:`
   - To:
     - `- [x] 014 Update or add LiveView tests for:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0001 / 0015: Coverage remains in Phoenix/LiveView surfaces.
   - ADR 0013: Added user-facing Phoenix/LiveView-style web tests using project test helpers/selectors.
   - ADR 0007: Membership and Messaging boundaries remain unchanged; tests use public Membership queries/commands.
   - ADR 0004 / 0006 / 0009: No message delivery semantics, status mapping, or projection plumbing changed.