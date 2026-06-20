1. **Selected todo line**
   - `- [ ] 002 Update the EmailDelivery projection/read model so newly created records start with status pending and can store dispatch diagnostics such as attempt count, latest error/detail, and useful timestamps.`

2. **Changes made**
   - Updated `Memba.Messaging.Projectors.EmailDelivery` so `EmailDeliveryCreated` now projects core `EmailDelivery` rows with:
     - `status: "pending"`
     - `attempt_count: 0`
   - Expanded `Memba.Messaging.Projections.EmailDelivery` with dispatch diagnostic fields:
     - `attempt_count`
     - `latest_error`
     - `latest_detail`
     - `last_dispatch_attempted_at`
     - `sent_at`
     - `failed_at`
   - Added generated migration:
     - `web/priv/repo/migrations/20260620065515_add_dispatch_diagnostics_to_messaging_email_deliveries.exs`
   - Updated focused/dependent tests to expect newly created core delivery records to be `pending` with empty diagnostics.
   - Adjusted existing admin/browser harness assertions where they inspect the core delivery read model status.

3. **Focused validation run**
   - Generated migration:
     - `env -u PGHOST -u PGPORT PATH="$PWD/bin:$PATH" bin/mix ecto.gen.migration add_dispatch_diagnostics_to_messaging_email_deliveries`
   - Format check:
     - `env -u PGHOST -u PGPORT PATH="$PWD/bin:$PATH" bin/mix format --check-formatted ...`
     - Passed.
   - Focused tests:
     - `devenv shell -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba/messaging/message_projection_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs test/memba_web/live/admin_diagnostics_live_test.exs test/memba_web/live/browser_acceptance_harness_test.exs'`
     - Passed: `24 tests, 0 failures`.
   - Broad quick check:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `799 tests, 0 failures`.
   - Full check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `799 tests, 0 failures`; acceptance `82 scenarios (82 passed)`.
   - Whitespace:
     - `git diff --check`
     - Passed.
   - Final task diff is staged with no unstaged changes.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Update the EmailDelivery projection/read model so newly created records start with status pending and can store dispatch diagnostics such as attempt count, latest error/detail, and useful timestamps.`
   - To:
     - `- [x] 002 Update the EmailDelivery projection/read model so newly created records start with status pending and can store dispatch diagnostics such as attempt count, latest error/detail, and useful timestamps.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0002 / 0009: kept this as a Commanded Ecto projection/read-model change.
   - ADR 0004 / 0005: preserved message aggregate/event ownership; only changed projected delivery state.
   - ADR 0006: did not add raw provider diagnostics to member-facing projections.
   - ADR 0007: stayed within Messaging read models and did not cross into Membership storage.
   - ADR 0021 / 0022: kept projection publishing/barrier responsibilities unchanged; no provider side effects were introduced in projection/replay paths.