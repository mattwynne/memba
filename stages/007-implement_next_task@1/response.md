Implemented the first unchecked task.

1. **Selected todo line**
   - `001 Use TDD with PhoenixTest as the preferred high-level LiveView test API. Start by writing failing PhoenixTest coverage for the real route flows listed in the acceptance criteria.`

2. **Changes made**
   - Added PhoenixTest-based browser flow coverage in:
     - `web/test/memba_web/live/browser_acceptance_harness_test.exs`
   - The new tests cover the planned browser behaviours:
     - visiting `/clubs`;
     - creating a club;
     - creating people;
     - adding members;
     - sending a club message;
     - viewing `/messages/:message_id`;
     - addressed-recipient visibility;
     - non-member exclusion;
     - one delivery/receipt per addressed member;
     - receipt status updates after delivery status reporting APIs are invoked.
   - Added `MembaWeb.FeatureCase` for PhoenixTest feature-style tests that need event-sourced isolation:
     - `web/test/support/feature_case.ex`
   - Exposed reusable event-sourced test setup from:
     - `web/test/support/event_sourced_case.ex`
   - Updated `MembaWeb.ConnCase` to attach the PhoenixTest endpoint to built conns:
     - `web/test/support/conn_case.ex`

3. **Validation run**
   - `cd web && mix format test/support/conn_case.ex test/support/event_sourced_case.ex test/support/feature_case.ex test/memba_web/live/browser_acceptance_harness_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Failed as expected for this TDD red step.
     - Final result: `95 tests, 2 failures`.
     - Failures are the intended missing browser routes:
       - `"/clubs" path doesn't exist`
       - `"/messages/:message_id" path doesn't exist`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 ...`
   - To:
     - `- [x] 001 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0013: followed the decision to use `PhoenixTest` for feature-style web tests.
   - ADR 0010: did not duplicate or alter shared acceptance feature files; no `*.feature` files were edited.
   - The new test coverage intentionally drives real Phoenix routes and leaves implementation for the next todo tasks.