Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `005 Add context/read-model queries as needed:`

2. **Changes made**
   - Added Membership staff operations query support in `web/lib/memba/membership.ex`:
     - `list_operator_people/0`
       - Returns one row per person.
       - Includes primary email, alternate emails, and active membership summaries.
       - Uses batched read-model lookups to avoid per-person N+1 queries.
     - `list_club_summaries/1`
       - Public bulk club summary API for other contexts.
     - `list_person_contact_summaries/1`
       - Public bulk person contact summary API for message sender enrichment.
   - Added Messaging staff operations query support in `web/lib/memba/messaging.ex`:
     - `list_operator_messages/0`
       - Lists projected messages newest-first.
       - Enriches rows with club and sender context where available.
       - Uses Membership public query APIs rather than joining directly to Membership projections.
   - Updated tests:
     - `web/test/memba/membership/query_test.exs`
     - `web/test/memba/messaging/message_projection_test.exs`
     - `web/test/memba/membership/no_crud_spike_test.exs`
     - `web/test/memba/messaging/no_crud_spike_test.exs`

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted ...`
     - Passed.
   - Focused query/API tests via `devenv shell` because the direct wrapper hit the known sandbox Postgres readiness issue:
     - `bin/mix test test/memba/membership/query_test.exs test/memba/messaging/message_projection_test.exs test/memba/membership/no_crud_spike_test.exs test/memba/messaging/no_crud_spike_test.exs`
     - Passed: `27 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `518 tests, 0 failures`.
   - Full validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `518 tests, 0 failures`
       - Acceptance: `34 scenarios (34 passed), 215 steps (215 passed)`
   - `git diff --check`
     - Passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 005 Add context/read-model queries as needed:`
   - To:
     - `- [x] 005 Add context/read-model queries as needed:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007: Messaging enriches message rows through Membership public query APIs, not direct Membership projection storage access.
   - ADR 0009: Queries read existing Commanded Ecto projection tables/read models.
   - ADR 0013: Added focused automated tests around user-relevant query behaviour.
   - ADR 0021/0022: No projection/event synchronization semantics were changed; this task only adds read-model query APIs.