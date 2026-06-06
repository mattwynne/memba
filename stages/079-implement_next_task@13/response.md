1. **Selected todo line**
   - `013 Implement conversion transactionally where practical: create club, create/reuse person, create active membership, mark request converted, and send/wrap welcome email behaviour consistently.`

2. **Changes made**
   - Added `Memba.Onboarding.convert_request_to_club/3`:
     - validates/fetches an active request,
     - creates the club via existing `Membership.create_club/2`,
     - reuses an existing person by requester email or creates a new person,
     - creates an active membership,
     - marks the request converted with converted club/person/membership IDs,
     - runs a post-conversion welcome-email wrapper and returns its result without rolling back successful conversion.
   - Updated staff `/admin/requests` LiveView:
     - conversion form now submits instead of being a placeholder,
     - successful conversion removes the request from the active inbox and updates count/flash,
     - invalid/taken slugs and stale/non-active requests are handled.
   - Added focused conversion tests:
     - new context test file for conversion record creation, existing-person reuse, failure behaviour, and welcome-email wrapper handling,
     - LiveView test proving staff can convert an active request into a club and active first member.
   - Checked off exactly task `013` in `todo.md`.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/onboarding_conversion_test.exs`
     - Passed: `4 tests, 0 failures`
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/admin/requests_live/index_test.exs`
     - Passed: `7 tests, 0 failures`
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/onboarding.ex lib/memba_web/live/admin/requests_live/index.ex test/memba/onboarding_conversion_test.exs test/memba_web/live/admin/requests_live/index_test.exs`
     - Passed
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `562 tests, 0 failures`
     - Acceptance: `38 scenarios (38 passed), 252 steps (252 passed)`
   - `git diff --check`
     - Passed

4. **Todo check-off made**
   - Changed:
     - `- [ ] 013 Implement conversion transactionally where practical: create club, create/reuse person, create active membership, mark request converted, and send/wrap welcome email behaviour consistently.`
   - To:
     - `- [x] 013 Implement conversion transactionally where practical: create club, create/reuse person, create active membership, mark request converted, and send/wrap welcome email behaviour consistently.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan references no explicit ADRs, and no `docs/adr/**/*.md` files were present.
   - Followed local project guidance:
     - LiveView form handling with stable IDs and server-side validation,
     - Ecto transaction/changeset practices for request state transitions,
     - existing Membership command APIs and shared slug validation behaviour,
     - welcome email kept as an external post-conversion side effect so DB/event-sourced record creation is not rolled back by email delivery failure.