Implemented the next unchecked task.

1. **Selected todo line**
   - `010 Build the active requests inbox with clear request details and actions for reject/convert.`

2. **Changes made**
   - Replaced the `/admin/requests` placeholder with an active requests inbox.
   - `MembaWeb.Admin.RequestsLive.Index` now:
     - loads `Onboarding.list_active_requests/0`;
     - shows active request count and summary cards;
     - streams active requests oldest-first;
     - displays requester name/email, request ID, requested club name, note, submitted time, and active status;
     - renders per-request `Reject` and `Convert` action buttons with stable IDs/data attributes for later task wiring.
   - Updated `web/test/memba_web/live/admin/requests_live/index_test.exs` to prove:
     - the inbox/table/toolbar render for staff;
     - only active requests appear;
     - rejected/converted requests are excluded;
     - request details and submitted time are shown;
     - reject/convert action controls are present.

3. **Validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba_web/live/admin/requests_live/index.ex test/memba_web/live/admin/requests_live/index_test.exs` — passed.
   - Focused `bin/mix test test/memba_web/live/admin/requests_live/index_test.exs` attempts were blocked by sandbox Postgres readiness/lock state.
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `553 tests, 0 failures`
     - `38 scenarios (38 passed), 252 steps (252 passed)`
   - `git diff --check` — passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 010 Build the active requests inbox with clear request details and actions for reject/convert.`
   - To:
     - `- [x] 010 Build the active requests inbox with clear request details and actions for reject/convert.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan did not explicitly reference any ADR.
   - No `docs/adr/**/*.md` files were present to inspect.
   - Followed local Phoenix/LiveView project guidance: used LiveView streams for the request collection, stable DOM IDs/selectors, and focused LiveView tests.