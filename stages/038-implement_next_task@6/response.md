Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 006 Update Postmark webhook handling so open events are treated as unsupported and do not mutate delivery status.`

2. **Changes made**
   - `web/lib/memba_web/controllers/postmark_webhook_controller.ex`
     - Added explicit unsupported handling for Postmark `Open` and `Opened` record types.
   - `web/test/memba_web/controllers/postmark_webhook_controller_test.exs`
     - Added coverage proving Postmark `Open` and `Opened` webhook events return `422`.
     - Verified those webhook events do not mutate member or Memba staff delivery status before delivery; status remains `sent`.
   - `docs/iterations/017-remove-open-tracking/todo.md`
     - Checked off task `006` only.

3. **Focused validation**
   - `cd web && mix format --check-formatted lib/memba_web/controllers/postmark_webhook_controller.ex test/memba_web/controllers/postmark_webhook_controller_test.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `378 tests, 0 failures`.
   - `git diff --check`
     - Passed.
   - Attempted direct focused `mix test test/memba_web/controllers/postmark_webhook_controller_test.exs`, but it cannot run outside the dev wrapper in this environment because the Postgres socket is unavailable. The required `dev check` started required services and passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 006 Update Postmark webhook handling so open events are treated as unsupported and do not mutate delivery status.`
   - To:
     - `- [x] 006 Update Postmark webhook handling so open events are treated as unsupported and do not mutate delivery status.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Inspected relevant ADRs around message deliverability, provider webhooks, and previous opened assumptions: ADR 0004, 0006, 0012, and 0016.
   - This task preserves the existing Postmark webhook endpoint and provider-boundary design.
   - ADRs 0006/0012/0016 contain older opened/open lifecycle assumptions; this approved iteration plan intentionally supersedes those assumptions for current behaviour.
   - No aggregate, projection architecture, routing boundary, or provider switching architecture was changed.