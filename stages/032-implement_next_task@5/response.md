Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005 Add member message detail at GET /messages/:message_id?club_id=<club_id>:`

2. **Changes made**
   - Added member route:
     - `GET /messages/:message_id?club_id=<club_id>`
     - Routed through a new required active-club-member pipeline.
   - Added `PageController.show_message/2`:
     - requires/normalizes `club_id`;
     - uses active membership authorization via the route pipeline;
     - verifies the message belongs to the requested club;
     - returns forbidden/not-found using the existing conventions;
     - assigns message, sender, member receipts, and grouped receipt data.
   - Added member-facing message detail template:
     - shows subject, body, sender, club-home backlink;
     - shows addressed members grouped by member receipt status;
     - exposes stable member receipt rows for tests;
     - avoids delivery IDs, recipient email addresses, provider/channel status, and operator reason text.
   - Updated tests:
     - `PageControllerTest` covers member detail rendering, redirect return path, forbidden non-member access, and message/club mismatch not-found behavior.
     - `RouterTest` now recognizes `/messages/:message_id` as the member message route instead of treating it as a removed harness route.

3. **Focused validation**
   - `cd web && mix format --check-formatted && mix compile --warnings-as-errors`
     - Passed.
   - Focused controller test with temporary PostgreSQL:
     - `mix test test/memba_web/controllers/page_controller_test.exs`
     - Passed: `14 tests, 0 failures`.
   - Acceptance support unit tests:
     - `cd acceptance-tests && node --test test/member_message_steps.test.js test/member_harness.test.js`
     - Passed: `22 tests, 0 failures`.
   - Phoenix precommit gate with temporary PostgreSQL:
     - `mix precommit`
     - Passed: `208 tests, 0 failures`.
   - Required `dev check`:
     - Direct `PATH="$PWD/bin:$PATH" dev check` attempts were blocked by external `devenv.cachix.org` HTTP 500 errors.
     - Re-ran `dev check` using the cached devenv profile with a ready temporary PostgreSQL instance to avoid the external Cachix failure.
     - Passed: `208 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Add member message detail at GET /messages/:message_id?club_id=<club_id>:`
   - To:
     - `- [x] 005 Add member message detail at GET /messages/:message_id?club_id=<club_id>:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: stayed within Phoenix controller/router/HEEx conventions.
   - ADR 0004/0005: consumed existing message and member receipt projections; did not change aggregate or recipient-resolution behavior.
   - ADR 0006: used member receipt projection statuses only and kept operator deliverability details off member pages.
   - ADR 0013: added Phoenix web tests for user-facing route behavior.
   - No acceptance feature files were edited.