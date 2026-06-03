1. **Selected todo line**
   - `002 Inspect iteration 019's provider-neutral inbound email API, idempotency model, rejection-email path, Resend inbound parser/controller, provider selection, and tests.`

2. **Changes made**
   - Added durable inspection artifact:
     - `docs/iterations/020-migrate-production-email-to-postmark/task-002-iteration-019-inbound-inspection.md`
   - The note documents:
     - Iteration 019 provider-neutral inbound API.
     - Event-sourced idempotency model.
     - Shared accepted/rejected inbound business flow.
     - Rejection-email delivery path.
     - Resend inbound parser/controller shape.
     - Provider selection model.
     - Existing test coverage to preserve/extend.
     - ADR conformance and Postmark carry-forward decisions.
   - Updated only the task 002 checkbox in:
     - `docs/iterations/020-migrate-production-email-to-postmark/todo.md`

3. **Focused validation**
   - Initial `bin/mix test ...` attempts failed before tests ran because the bare sandbox PATH lacked `pg_isready`, causing the wrapper’s Postgres readiness check to fail.
   - Retried inside `devenv shell` for this specific wrapper issue:
     - `mix test test/memba/messaging/inbound_email_api_test.exs test/memba/messaging/inbound_email_dispatch_test.exs test/memba/messaging/inbound_email_receipt_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs test/memba_web/resend_inbound_email_parser_test.exs test/memba_web/controllers/resend_inbound_webhook_controller_test.exs test/memba/messaging/email_delivery_provider_config_test.exs`
     - Result: `45 tests, 0 failures`
   - Ran:
     - `git diff --check`
     - Result: passed.
   - Did **not** run full `dev check` because this was a docs/inspection-only task; full `dev check` remains task 016.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Inspect iteration 019's provider-neutral inbound email API, idempotency model, rejection-email path, Resend inbound parser/controller, provider selection, and tests.`
   - To:
     - `- [x] 002 Inspect iteration 019's provider-neutral inbound email API, idempotency model, rejection-email path, Resend inbound parser/controller, provider selection, and tests.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read and applied ADR 0016: Resend remains a first-class switchable provider alongside Postmark; provider-specific parsing stays at the boundary while domain behaviour remains provider-neutral.
   - Reviewed nearby/current ADRs 0014, 0017, and 0018:
     - 0014/0017 support explicit production email/Fly/runbook treatment for later tasks.
     - 0018 confirmed no devenv/process-compose changes were appropriate for this inspection task.