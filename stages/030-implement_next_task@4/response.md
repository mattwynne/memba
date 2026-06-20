1. **Selected todo line**
   - `- [ ] 004 Introduce a named dispatch module/process, probably Memba.Messaging.EmailDeliveryDispatcher, under the application supervision tree.`

2. **Changes made**
   - Added `web/lib/memba/messaging/email_delivery_dispatcher.ex`
     - Defines `Memba.Messaging.EmailDeliveryDispatcher` as a named `GenServer`.
     - Keeps it intentionally minimal; subscription/claim/provider/retry behavior remains for later todo tasks.
   - Updated `web/lib/memba/application.ex`
     - Adds `Memba.Messaging.EmailDeliveryDispatcher` to the application supervision tree after messaging provider support processes and before messaging projectors.
   - Updated `web/test/memba/messaging/app_test.exs`
     - Adds focused assertions that the dispatcher is registered and supervised by `Memba.Supervisor`.

3. **Focused validation commands run and results**
   - TDD pre-implementation focused test:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/messaging/app_test.exs'`
     - Failed as expected because `Process.whereis(Memba.Messaging.EmailDeliveryDispatcher)` was `nil`.
   - Formatting:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/application.ex lib/memba/messaging/email_delivery_dispatcher.ex test/memba/messaging/app_test.exs`
     - Passed.
   - Focused test:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/messaging/app_test.exs'`
     - Passed: `4 tests, 0 failures`.
   - Broad quick check after todo check-off:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `802 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Introduce a named dispatch module/process, probably Memba.Messaging.EmailDeliveryDispatcher, under the application supervision tree.`
   - To:
     - `- [x] 004 Introduce a named dispatch module/process, probably Memba.Messaging.EmailDeliveryDispatcher, under the application supervision tree.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002 / CQRS: Added an OTP dispatch boundary without changing command handling or event semantics.
   - ADR 0009: Did not change projection mechanics or replay behavior.
   - ADR 0021: Dispatcher is supervised after PubSub and before projectors, positioning it for the next task’s committed read-model-change subscription without altering publisher behavior.
   - ADR 0016: No provider adapter/runtime-provider behavior was changed.
   - ADR 0006: No member-facing UI/status presentation was changed.