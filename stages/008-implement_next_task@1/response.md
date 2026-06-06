1. **Selected todo line**
   - `001 Inspect the v2 source artifacts in docs/iterations/024-email-template-designs/source/ and current email-building modules/tests.`

2. **Changes made**
   - Inspected the v2 design artifacts:
     - `email-system-spec-v2.html`
     - `sign-in-link-v2.html`
     - `member-message-v2.html`
     - `inbound-rejection-v2.html`
   - Inspected current email-building code:
     - `web/lib/memba/accounts/auth_email.ex`
     - `web/lib/memba/onboarding/welcome_email.ex`
     - `web/lib/memba/messaging/email_delivery_providers/postmark.ex`
     - `web/lib/memba/messaging/email_delivery_providers/local.ex`
     - `web/lib/memba/messaging/inbound_club_rejection_email.ex`
     - related auth sign-in call site in `web/lib/memba_web/live/auth_live/sign_in.ex`
   - Inspected current email-related tests, including:
     - `web/test/memba/accounts/auth_email_test.exs`
     - `web/test/memba/onboarding/welcome_email_test.exs`
     - `web/test/memba/messaging/email_delivery_providers/postmark_test.exs`
     - `web/test/memba/messaging/email_delivery_providers/local_test.exs`
     - inbound rejection coverage in `web/test/memba/messaging/inbound_club_message_acceptance_test.exs` and controller tests.
   - Checked off only the selected task in `todo.md`.

   Key inspection findings for later tasks:
   - Current HTML is minimal/plain and locally duplicated across email modules.
   - Member-message `text_body` currently preserves sender body exactly; HTML is escaped line-break conversion only.
   - `EmailDeliveryRequest` currently does not carry club name, only `club_id`, so later member-message group-led rendering may need either request shape changes or cheap lookup/caller enrichment.
   - Auth email currently has only `deliver_sign_in_link/2`, Memba-led subject/from/body, and provider options that must be preserved.
   - Onboarding welcome email already has club context and currently builds separate bare HTML instead of sharing auth email rendering.
   - Inbound rejection currently preserves threading and metadata/tags, but reason copy and subject rules differ from the v2 spec.

3. **Focused validation**
   - Ran:
     - `git log --oneline --decorate -20` — reviewed recent Fabro checkpoints.
     - `git status --short` before editing — clean tree.
     - Relevant file reads/searches for artifacts, ADRs, email modules, and tests.
     - `git diff -- docs/iterations/024-email-template-designs/todo.md` — confirmed only the intended todo check-off.
     - `git status --short` after editing — only `docs/iterations/024-email-template-designs/todo.md` modified.
   - Did **not** run `dev check`; this task was inspection/todo-state only and made no code/config/behaviour changes.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 001 Inspect the v2 source artifacts in docs/iterations/024-email-template-designs/source/ and current email-building modules/tests.`
   - To:
     - `- [x] 001 Inspect the v2 source artifacts in docs/iterations/024-email-template-designs/source/ and current email-building modules/tests.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Reviewed relevant accepted ADRs:
     - ADR 0001: Phoenix remains the core app boundary.
     - ADR 0004: messaging deliverability aggregate remains unchanged.
     - ADR 0016: Postmark/Resend provider switchability must be preserved.
     - ADR 0020: production email smoke-test scope remains unaffected.
   - This task made no architecture or behaviour changes and introduced no conflicts with those ADRs.