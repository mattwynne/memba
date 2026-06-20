1. **Selected todo line**
   - `- [ ] 013 Add/update focused tests for the acceptance criteria above.`

2. **Changes made for this task**
   - Added `web/test/support/messaging/email_delivery_providers/selective_failure.ex`
     - Test-only provider that records all delivery attempts and fails configured recipient addresses.
   - Updated `web/test/memba/messaging/email_delivery_dispatcher_test.exs`
     - Added coverage that one recipient/provider failure is persisted as a failed delivery while later deliveries for the same message are still dispatched and marked `sent`.
   - Updated `web/test/memba/messaging/send_club_message_test.exs`
     - Added coverage that manual retry of a failed delivery does **not** append duplicate `MessageSent` or `EmailDeliveryCreated` events.
     - Added coverage that projector replay rebuilds pending `EmailDelivery` records without handing anything to the provider.

3. **Validation commands/results**
   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/support/messaging/email_delivery_providers/selective_failure.ex test/memba/messaging/email_delivery_dispatcher_test.exs test/memba/messaging/send_club_message_test.exs`
     - Passed.
   - Focused tests:
     - `devenv shell -- bash -lc 'cd web && PATH="$PWD/../bin:$PATH" ../bin/mix test test/memba/messaging/email_delivery_dispatcher_test.exs test/memba/messaging/send_club_message_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs'`
     - Passed: `37 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Passed.
   - Broad quick check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Reached the acceptance suite and reported `8` existing Cucumber failures around acceptance steps still expecting synchronous provider deliveries (`Fake.deliveries()` immediately populated). I did **not** claim this as passing; fixing those regressions remains the next unchecked task `014`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 013 Add/update focused tests for the acceptance criteria above.`
   - To:
     - `- [x] 013 Add/update focused tests for the acceptance criteria above.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002 / 0004: Tests keep message/delivery behaviour in the Commanded/event-sourced messaging model and verify no duplicate domain events on retry.
   - ADR 0005 / 0007: Tests preserve resolved-recipient delivery ownership in Messaging without crossing into Membership storage internals.
   - ADR 0016: Test provider remains a switchable provider-boundary seam; no new HTTP/client dependency introduced.
   - ADR 0021 / 0022: Replay test uses projection/barrier mechanics to verify read-model rebuild behaviour without provider side effects.