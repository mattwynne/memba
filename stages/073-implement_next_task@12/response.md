1. **Selected todo line**
   - `012 Update docs/postmark-email.md to describe the full Postmark production setup: outbound member-message stream, auth stream, inbound club-message routing for clubs.memba.io, delivery-status webhook URL, inbound webhook URL, environment variables, and local smoke-test guidance.`

2. **Changes made**
   - Updated `docs/postmark-email.md` only for this documentation task:
     - Added a production Postmark setup overview table.
     - Documented:
       - member broadcast stream `outbound-member-broadcasts`
       - auth stream `outbound-authentication`
       - inbound routing for `<club-slug>@clubs.memba.io`
       - `clubs.memba.io` MX target `inbound.postmarkapp.com`
       - delivery-status webhook URL `/webhooks/postmark`
       - inbound webhook URL `/webhooks/postmark/inbound`
       - production Postmark env vars
       - local smoke-test guidance for member-message, auth, and inbound paths
       - manual production smoke-test coverage for inbound/rejection email
     - Clarified that member broadcasts reply to the member sender, while `MEMBA_POSTMARK_REPLY_TO_ADDRESS` is for provider-backed rejection/contact reply behaviour.
   - Updated `docs/iterations/020-migrate-production-email-to-postmark/todo.md` to check off task 012 only.

3. **Focused validation commands run and results**
   - `git diff --check`
     - Passed.
   - `grep -nE "outbound-member-broadcasts|outbound-authentication|clubs\.memba\.io|/webhooks/postmark/inbound|/webhooks/postmark$|MEMBA_MESSAGING_DELIVERY_PROVIDER=postmark|MEMBA_AUTH_EMAIL_PROVIDER=postmark|Local smoke-test guidance" docs/postmark-email.md`
     - Passed; confirmed the required production setup topics are present.
   - `git diff -- docs/iterations/020-migrate-production-email-to-postmark/todo.md`
     - Confirmed only task 012 changed from unchecked to checked.
   - I did **not** run `dev check` because this was a docs-only/prose-only change, per project guidance.

4. **Exact todo check-off made**
   - Changed:
     ```md
     - [ ] 012 Update `docs/postmark-email.md` to describe the full Postmark production setup: outbound member-message stream, auth stream, inbound club-message routing for `clubs.memba.io`, delivery-status webhook URL, inbound webhook URL, environment variables, and local smoke-test guidance.
     ```
   - To:
     ```md
     - [x] 012 Update `docs/postmark-email.md` to describe the full Postmark production setup: outbound member-message stream, auth stream, inbound club-message routing for `clubs.memba.io`, delivery-status webhook URL, inbound webhook URL, environment variables, and local smoke-test guidance.
     ```

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0016 preserved: Postmark and Resend remain documented as switchable providers, provider-specific webhook routes stay at the boundary, and Swoosh/provider configuration remains runtime-selected.
   - ADR 0017 respected: production email cutover documentation now explicitly names environment variables, webhook URLs, smoke-test expectations, and operational setup that Matt must verify manually.
   - No code, routing, migrations, acceptance feature files, or runtime behaviour were changed.