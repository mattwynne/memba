1. **Selected todo line**
   - `- [ ] 006 Implement claiming logic that moves a pending delivery to dispatching before provider delivery, avoiding two dispatcher invocations claiming the same pending delivery concurrently.`

2. **Changes made**
   - Added DB-backed claiming to `Memba.Messaging.EmailDeliveryDispatcher`:
     - `claim_pending_delivery/1` atomically updates a delivery from `pending` to `dispatching` using a conditional `Repo.update_all/2`.
     - Sets `last_dispatch_attempted_at` and `updated_at` on successful claim.
     - Returns `:not_claimed` for non-pending/nonexistent/invalid IDs.
     - `claim_pending_email_deliveries/0` lists pending delivery IDs and claims each with the atomic single-row claim.
   - Updated dispatcher nudge handling to claim pending deliveries when dispatch is enabled.
   - Added `dispatch_enabled` option for the dispatcher.
   - Updated application supervision to pass dispatcher config.
   - Disabled app-level dispatcher DB claiming in `config/test.exs` so ordinary tests avoid SQL sandbox ownership races; focused dispatcher tests opt in with their own supervised dispatcher.
   - Expanded `email_delivery_dispatcher_test.exs` to cover:
     - read-model-change nudge claims pending delivery,
     - dispatch-disabled mode leaves pending delivery alone,
     - single pending claim,
     - non-pending delivery not claimed,
     - concurrent claim attempts allow only one winner,
     - batch claiming skips already-claimed work.

3. **Focused validation commands run**
   - Formatting check:
     - `cd web && PATH="$PWD/../bin:$PATH" ../bin/mix format --check-formatted lib/memba/messaging/email_delivery_dispatcher.ex lib/memba/application.ex config/test.exs test/memba/messaging/email_delivery_dispatcher_test.exs`
     - Passed.
   - Focused dispatcher tests:
     - Initial plain run failed due stale `PGHOST=/tmp/devenv/postgres` while Postgres started at `/tmp/devenv-*`.
     - Rerun:
       - `devenv shell -- bash -lc 'cd web && PATH="$PWD/../bin:$PATH" ../bin/mix test test/memba/messaging/email_delivery_dispatcher_test.exs'`
       - Passed: `7 tests, 0 failures`.
   - Affected supervision/projection/status tests:
     - `devenv shell -- bash -lc 'cd web && PATH="$PWD/../bin:$PATH" ../bin/mix test test/memba/messaging/app_test.exs test/memba/messaging/message_projection_test.exs test/memba/messaging/email_delivery_status_constraints_test.exs'`
     - Passed: `9 tests, 0 failures`.
   - Broad quick check:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" dev check --quick'`
     - Passed: `809 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Implement claiming logic that moves a pending delivery to dispatching before provider delivery, avoiding two dispatcher invocations claiming the same pending delivery concurrently.`
   - To:
     - `- [x] 006 Implement claiming logic that moves a pending delivery to dispatching before provider delivery, avoiding two dispatcher invocations claiming the same pending delivery concurrently.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002 / CQRS: claiming is outside aggregate command handling and does not add provider side effects to commands.
   - ADR 0009: projections remain projection-only; claiming updates the read model from the dispatcher, not during projector replay.
   - ADR 0016: no provider selection/adapter behavior changed.
   - ADR 0021: dispatcher still reacts to committed read-model-change PubSub nudges.
   - ADR 0022: did not use projection barriers or conflate them with read-model-change notifications.