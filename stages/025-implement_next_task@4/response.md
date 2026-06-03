1. **Selected todo line**
   - `004 Determine the cleanest Postmark inbound routing shape. Prefer keeping inbound-email handling separate from outbound delivery-status webhooks if Postmark's dashboard supports separate inbound and delivery-status webhook URLs; otherwise make the shared Postmark route dispatch safely by payload shape.`

2. **Changes made**
   - Added decision artifact:
     - `docs/iterations/020-migrate-production-email-to-postmark/task-004-postmark-inbound-routing-decision.md`
   - Decision recorded:
     - Use a separate Postmark inbound route: `POST /webhooks/postmark/inbound`
     - Keep existing delivery-status route unchanged: `POST /webhooks/postmark`
     - Later implementation should add a dedicated `MembaWeb.PostmarkInboundWebhookController`, not payload-shape dispatch inside the existing delivery-status controller.
   - Documented supporting Postmark facts:
     - Inbound webhook URL is an Inbound Message Stream setting.
     - Delivery webhooks are configured separately via message-stream webhook settings/API.
     - `MessageID` should be the first-choice Postmark inbound idempotency field for later parser work.
     - Inbound payload includes sender, recipients, text/HTML bodies, headers, and attachment metadata.
     - Production inbound domain setup should route `clubs.memba.io` MX to `inbound.postmarkapp.com`.

3. **Focused validation**
   - Ran:
     - `git diff --check`
     - trailing-whitespace check over touched Markdown files
     - confirmed first unchecked todo is now task `005`
   - Results:
     - Passed.
   - Did **not** run `dev check` because this task only added an iteration decision document and updated one todo checkbox; no executable code/config/app behaviour changed.

4. **Exact todo check-off made**
   - Changed only:
     - `- [ ] 004 Determine the cleanest Postmark inbound routing shape...`
   - To:
     - `- [x] 004 Determine the cleanest Postmark inbound routing shape...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0016 respected: Postmark/Resend remain provider-specific at webhook boundaries, while shared domain APIs stay provider-neutral.
   - Existing `/webhooks/postmark` delivery-status route remains unchanged, preserving current Postmark delivery webhook behaviour.
   - ADR 0014/0017 operational concerns carried forward by documenting exact future inbound URL and DNS/MX setup for the later runbook/docs tasks.
   - ADR 0018 unaffected; no devenv/process-compose/service orchestration changes were made.