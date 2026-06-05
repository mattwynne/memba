Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `008 Restyle /admin/clubs/:club_id around club facts, people records, and memberships.`

2. **Changes made**
   - Restyled `web/lib/memba_web/live/admin/clubs_live/show.ex`:
     - Added redesigned staff-operations layout for club detail.
     - Made club facts, person records, and memberships visually distinct:
       - `#club-facts-card`
       - `#club-facts-edit-card`
       - `#people-records-card`
       - `#memberships-card`
     - Added honest summary counts for projected person records, active memberships, and projected messages.
     - Converted people and membership areas to denser operations-style table/card treatments.
     - Preserved existing workflow selectors and behaviour for:
       - club edit form;
       - person creation/edit links;
       - membership add/remove form/list;
       - staff-side message form/list, which are intentionally still present for later tasks `009` and `010`.
     - Avoided changing domain, projection, messaging, or membership semantics.
   - Updated `web/test/memba_web/live/admin/clubs_live/show_test.exs`:
     - Added LiveView coverage that club detail separates club facts, person records, and memberships in the redesigned layout.

3. **Validation commands/results**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/live/admin/clubs_live/show.ex test/memba_web/live/admin/clubs_live/show_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/admin/clubs_live/show_test.exs`
     - Failed before tests ran due the known sandbox Postgres socket readiness mismatch.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && mix test test/memba_web/live/admin/clubs_live/show_test.exs'`
     - Passed: `7 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - First run found one acceptance failure caused by a duplicate club-name heading.
     - Fixed by keeping the page title as the only club-name heading.
   - Rerun: `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `522 tests, 0 failures`
       - Acceptance: `34 scenarios (34 passed), 215 steps (215 passed)`
   - `git diff --check`
     - Passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 008 Restyle /admin/clubs/:club_id around club facts, people records, and memberships.`
   - To:
     - `- [x] 008 Restyle /admin/clubs/:club_id around club facts, people records, and memberships.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001 respected: implementation stays in Phoenix LiveView.
   - ADR 0007 respected: no Membership/Messaging bounded-context semantics changed.
   - ADR 0009 respected: no projection structure or projection ownership changed.
   - ADR 0013 respected: added user-facing LiveView coverage for the changed admin page structure.
   - The staff composer and embedded message list were preserved for later explicit tasks `009` and `010`; this task only restyled/reorganized the detail page around club facts, people records, and memberships.