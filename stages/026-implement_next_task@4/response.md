1. **Selected todo line and task text**
   - Selected first unchecked task:
     - `004 Add routes and LiveViews for read-only /admin/people and /admin/messages under the existing staff live session.`

2. **Changes made**
   - Added routes inside the existing `:memba_staff` live session in `web/lib/memba_web/router.ex`:
     - `GET /admin/people` → `MembaWeb.Admin.PeopleLive.Index`
     - `GET /admin/messages` → `MembaWeb.Admin.MessagesLive.Index`
   - Added `web/lib/memba_web/live/admin/people_live/index.ex`:
     - Read-only global People page scaffold.
     - Staff operations header and read-only notice.
     - Stable selectors including `#admin-people-index`, `#admin-people-read-only-notice`, and `#admin-people-table`.
     - Empty streamed table ready for task 005’s query wiring.
   - Added `web/lib/memba_web/live/admin/messages_live/index.ex`:
     - Read-only global Messages page scaffold.
     - Staff operations header and read-only notice.
     - Stable selectors including `#admin-messages-index`, `#admin-messages-read-only-notice`, and `#admin-messages-table`.
     - Empty streamed table ready for task 005’s query wiring and future diagnostics links.
   - Added `web/test/memba_web/live/admin_operations_index_live_test.exs`:
     - Verifies the new indexes require staff sign-in.
     - Verifies signed-in Memba staff can open both pages.
     - Verifies key read-only page selectors and absence of unsupported form/action selectors.

3. **Focused validation commands run and results**
   - Initial TDD/focused run attempted before implementation:
     - `PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/admin_operations_index_live_test.exs`
     - Failed due sandbox Postgres readiness wrapper issue before reaching route assertions.
   - Formatting check:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/router.ex lib/memba_web/live/admin/people_live/index.ex lib/memba_web/live/admin/messages_live/index.ex test/memba_web/live/admin_operations_index_live_test.exs`
     - Passed.
   - Focused tests:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/live/admin_operations_index_live_test.exs'`
     - Passed: `3 tests, 0 failures`.
     - Used `devenv shell` because the bare wrapper repeatedly failed to detect the ready Postgres socket.
   - Whitespace check:
     - `git diff --check`
     - Passed.
   - Full validation required for routing/LiveView/browser-facing changes:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `516 tests, 0 failures`
       - Acceptance: `34 scenarios (34 passed), 215 steps (215 passed)`

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 004 Add routes and LiveViews for read-only /admin/people and /admin/messages under the existing staff live session.`
   - To:
     - `- [x] 004 Add routes and LiveViews for read-only /admin/people and /admin/messages under the existing staff live session.`

5. **Todo splits/additions/reordering**
   - None.
   - I did not check off `004a`; route-verifying the existing staff nav links remains the next explicit task.

6. **ADR conformance evidence**
   - ADR 0001: Kept the work in Phoenix/LiveView as the core application surface.
   - ADR 0007: Did not introduce cross-context read-model coupling; Membership/Messaging query enrichment remains deferred to task 005.
   - ADR 0013: Added Phoenix feature-style web coverage for route protection and user-visible page behavior.
   - ADR 0015: Used LiveView for these staff application pages, consistent with the app-surface pattern.
   - ADR 0021/0022: No read-model publication or projection-barrier behavior was changed; query/read-model wiring remains for later tasks.