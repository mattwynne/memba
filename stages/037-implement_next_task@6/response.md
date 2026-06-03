1. **Selected todo line**
   - `006 Reuse iteration 019's provider-neutral command/API for all accepted/rejected behaviour rather than duplicating business rules in Postmark-specific code.`

2. **Changes made**
   - Added a focused regression test in:
     - `web/test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs`
   - The new test proves Postmark inbound webhook handling reuses the provider-neutral `Messaging.receive_inbound_club_email/2` path for rejection outcomes:
     - Posts a valid Postmark inbound payload from an unknown sender.
     - Confirms the webhook returns `202 accepted`, not a provider-specific error.
     - Confirms no club message or outbound member deliveries are created.
     - Confirms the provider-neutral inbound source projection records:
       - `provider: "postmark"`
       - `status: "rejected"`
       - `rejection_reason: "unknown_sender"`
     - Confirms the shared rejection-email path sends the normal rejection email.

3. **Focused validation**
   - Initial focused test command:
     ```sh
     PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs
     ```
     - Failed because the sandbox had stale `PGHOST=/tmp/devenv/postgres` / `PGPORT=5432` while Postgres started on the sandbox override port.
   - Reran focused test with the existing sandbox port override:
     ```sh
     env -u PGHOST -u PGPORT MEMBA_POSTGRES_PORT=15432 devenv shell -O services.postgres.port:int 15432 -- bash -lc 'PATH="$PWD/bin:$PATH" bin/mix test test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs'
     ```
     - Result: `3 tests, 0 failures`
   - Formatting check:
     ```sh
     PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs
     ```
     - Result: passed
   - Broad per-task validation:
     ```sh
     PATH="$PWD/bin:$PATH" dev check --quick
     ```
     - Result: passed
     - ExUnit: `479 tests, 0 failures`

4. **Todo check-off made**
   - Changed exactly:
     ```md
     - [ ] 006 Reuse iteration 019's provider-neutral command/API for all accepted/rejected behaviour rather than duplicating business rules in Postmark-specific code.
     ```
   - To:
     ```md
     - [x] 006 Reuse iteration 019's provider-neutral command/API for all accepted/rejected behaviour rather than duplicating business rules in Postmark-specific code.
     ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0016 preserved: Postmark-specific code remains limited to webhook parsing/adapter behavior; accepted/rejected inbound business behavior stays in the provider-neutral Messaging API.
   - Resend remains untouched and selectable.
   - No routing, production hosting, release-state, or devenv/process orchestration changes, preserving ADRs 0014, 0017, and 0018.