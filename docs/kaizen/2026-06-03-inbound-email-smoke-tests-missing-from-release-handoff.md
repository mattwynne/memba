# Problem: Inbound email release lacks an end-to-end smoke-test spec

Date: 2026-06-03

## Context

While preparing to move club inbound email from Resend to Postmark during iteration 020 (`docs/iterations/020-migrate-production-email-to-postmark/plan.md`), we found that the product code and provider/DNS setup could be green while a real email still failed to produce the expected member-visible outcome.

The immediate manual test was an email sent at about 08:50 with subject `Test 2` from `matt@mattwynne.net` to `wynne-family@clubs.memba.io`. Instead of being rejected as an unknown sender by Memba, the original email landed back in Matt's inbox. Investigation showed Memba had not recorded any inbound source rows, and the operational setup was incomplete/misaligned across DNS, Resend, and Postmark.

During the follow-up, Matt asked for a focused smoke-test design that can be run manually now and later automated as part of deployment. He explicitly wanted only the real end-to-end email behaviour tests, not low-level DNS/provider/API checks.

## Expected standard

For a release that changes inbound email provider infrastructure, the deployment handoff should include a small real-email smoke-test spec that proves the externally observable behaviours:

- a real email from an unknown sender to a club inbound address is rejected and the sender receives rejection guidance;
- a real email from a known active member is accepted and distributed as a club message;
- unsupported real email content, such as attachments and HTML-only bodies, is rejected without creating a club message.

These tests are deployment smoke tests, not acceptance examples or unit/controller tests. They intentionally exercise the full path: sender mailbox → public DNS/MX → inbound provider → production webhook → Memba business rules → outbound/rejection email.

## What happened

We had automated and implementation-level coverage for inbound email rules, but no concise release smoke checklist for the real production path. The missing smoke spec made it harder to separate product-code correctness from provider/DNS/webhook configuration problems.

Evidence observed in this session:

- `dig MX clubs.memba.io` initially showed no direct `clubs.memba.io` MX, while `memba.io` still had Fastmail MX records.
- Resend had only `resend.memba.io` configured as a domain, with receiving disabled initially.
- Postmark had `mail.memba.io` verified for sending, but its `memba.io` server initially had no inbound domain and no inbound hook URL.
- Production Memba had no `messaging_inbound_email_sources` rows after the `Test 2` real email attempt, so the real message never made it through the business path.
- Production logs showed webhook attempts returning `422`, but that did not by itself tell us whether the failing boundary was DNS, provider setup, webhook shape, or product rules.

## Impact

This is a release-quality and operability risk. A deployment can appear complete after code checks and provider configuration changes, but the behaviour members care about may still be broken until someone sends a real message and inspects the result.

Without a small standard smoke spec, future provider migrations or webhook changes may repeat the same ambiguity and require manual archaeology across mailboxes, DNS, provider dashboards, Fly logs, and database projections.

## What allowed it to happen

The iteration plan covered Postmark migration and manual smoke testing at a broad level, but the delivery machinery did not have a reusable, focused, end-to-end smoke-test artifact for inbound club email.

The gap is not ordinary product test coverage. It is a missing deployment handoff/operational validation standard for a multi-system integration where the real failure can be outside the application code.

## Smoke-test spec to preserve

Use a unique timestamp in every subject, for example `2026-06-03 19:20`, so results are easy to find in mailboxes, logs, and projections.

### Smoke 1: Unknown sender is rejected

Send a real email:

```text
From: matt@mattwynne.net
To: wynne-family@clubs.memba.io
Subject: Smoke unknown sender <timestamp>

This should be rejected because the sender is unknown.
```

Expected result:

- No Wynne Family club message is created with that subject.
- Memba records the inbound email as rejected.
- Rejection reason is `unknown_sender`.
- `matt@mattwynne.net` receives a rejection email:
  - subject: `Your email was not posted`;
  - explains that Memba could not find a member account for the sender address;
  - includes support/contact guidance.

### Smoke 2: Known active member email is accepted

Send a real email from an address that belongs to an active Wynne Family club member:

```text
From: <known-active-member-address>
To: wynne-family@clubs.memba.io
Subject: Smoke accepted member <timestamp>

This should become a club message.
```

Expected result:

- A Wynne Family club message is created with that subject.
- The message sender is the matching member/person.
- The message body is the plain-text body.
- The message is addressed to active Wynne Family members only.
- Outbound copies are sent through Memba's normal club-message path.
- No separate acceptance confirmation is sent.

### Smoke 3: Attachment is rejected

Send a real email from a known active member address:

```text
From: <known-active-member-address>
To: wynne-family@clubs.memba.io
Subject: Smoke attachment rejected <timestamp>

This should be rejected because it has an attachment.
```

Attach any small file.

Expected result:

- No club message is created with that subject.
- Memba records the inbound email as rejected.
- Rejection reason is `attachments_not_supported`.
- Sender receives a `Your email was not posted` rejection.
- Rejection explains that attachments are not supported yet.

### Smoke 4: HTML-only email is rejected

Send a real email from a known active member address with no plain-text part, if the mail client/tool can produce that reliably:

```text
From: <known-active-member-address>
To: wynne-family@clubs.memba.io
Subject: Smoke HTML-only rejected <timestamp>
```

Expected result:

- No club message is created with that subject.
- Memba records the inbound email as rejected.
- Rejection reason is `plain_text_required`.
- Sender receives a `Your email was not posted` rejection.
- Rejection explains that a plain-text message body is required.

Note: this case may be awkward with ordinary mail clients because many automatically include a plain-text alternative. Keep it as a lower-priority/manual-special-case smoke test until there is a reliable scripted sender.

## Observations

- Matt wants the smoke spec to stay focused on real inbound email behaviours 4 and 5 from the earlier proposal, not DNS/provider configuration checks. Lower-level checks can be added later if needed, but they are not the desired smoke-test contract.
- Real email smoke tests should remain separate from stakeholder-readable acceptance scenarios. Acceptance scenarios describe the business rules; these smoke tests validate the deployed production integration.
- The most useful post-deploy minimum appears to be Smoke 1, Smoke 2, and Smoke 3. Smoke 4 needs a reliable HTML-only sender before it is suitable for routine automation.

## Why this matters

Inbound email spans several independently configurable systems. Automated app tests can pass while DNS, provider receiving, provider webhook configuration, webhook payload shape, or production secrets are wrong. A small real-email smoke spec makes that risk visible immediately after deploy and gives future automation a clear target.

## Open questions

- Where should this smoke spec live permanently: release runbook, `docs/postmark-email.md`, iteration 020 runbook, or a dedicated deployment smoke-test script?
- What known active member address should be used for routine production smoke tests without confusing real members?
- Should the accepted-message smoke test use a private/internal club or a production fixture club to avoid sending test messages to ordinary members?
- What tool should eventually send a true HTML-only email reliably for Smoke 4?

## Possible prevention ideas

- Add this smoke spec to the Postmark cutover/deployment runbook produced by iteration 020.
- Add a future script that sends the smoke emails with unique subjects and then polls Memba projections/mailboxes for expected outcomes.
- Add an operator-facing query or task that prints recent inbound email source records by subject/provider message id once the projection contains enough correlation data.

## Resolution

Date: 2026-06-03

Root cause: the deployment handoff had no executable production smoke-test artifact for the real inbound email path, so operator validation depended on ad hoc manual emails and investigation across mailboxes, provider dashboards, logs, and projections.

Fix applied:

- `smoke-tests/`: added a Cucumber smoke-test runner that sends real email through Fastmail SMTP, polls Fastmail mailboxes for rejection/distribution emails, and uses Playwright to check staff/member-visible Memba UI. The mailbox reader now supports Fastmail JMAP when an API token is available, waits on JMAP events between checks, and falls back to IMAP using `SMOKE_TEST_EMAIL_PASSWORD` / `MEMBA_SMOKE_FASTMAIL_PASSWORD`.
- `smoke-tests/features/inbound_club_email.feature`: captured the routine production wiring smoke cases: unknown sender rejected, known active member accepted/distributed, and known active member with attachment rejected.
- `smoke-tests/README.md`: documented the required `Smoke Test Club` fixture, `test@memba.io` member mailbox, credentials, and run commands.
- `docs/human-todo.md`: added and then updated Matt's external setup tasks for the controlled smoke club, Fastmail credentials, DNS, Postmark inbound configuration, and production provider cutover.
- `web/priv/repo/seeds.exs`: seeds `Smoke Test Club` with slug `test`, `Smoke Tester <test@memba.io>`, and an active membership.
- `MembaWeb.PageController`: hard-codes slug `test` as hidden from public club pages while preserving staff/member/inbound use.
- Production setup applied during the session: `clubs.memba.io` MX points to `inbound.postmarkapp.com`; Postmark `memba.io` server has inbound domain `clubs.memba.io` and inbound hook `https://memba.io/webhooks/postmark`; production selects Postmark for messaging and auth email; production database contains the smoke-test club/member fixture.

Validation:

- `node --check smoke-tests/lib/config.js && node --check smoke-tests/lib/fastmail_jmap.js && node --check smoke-tests/lib/smtp.js && node --check smoke-tests/lib/browser.js && node --check smoke-tests/features/support/world.js && node --check smoke-tests/features/step_definitions/inbound_club_email_steps.js` — passed.
- `cd smoke-tests && npm test -- --dry-run` — passed; Cucumber discovered 3 scenarios and 21 steps.

Remaining follow-up:

- The production smoke runner can sign staff/member in through `test@memba.io`, can see the smoke-test club in staff UI, and can send mail through Fastmail SMTP using `test+x@memba.io` as an unknown sender.
- The current production smoke failure is downstream of sending: Postmark is not showing inbound messages for `test@clubs.memba.io` (`/messages/inbound` returned `TotalCount: 0`), and Memba logs show no `POST /webhooks/postmark` for those test emails. This suggests the remaining abnormality is still at the provider receiving/MX acceptance boundary, not mailbox access or app sign-in.
- The smoke runner now assumes `Smoke Test Club`, not `Test`, and production contains that fixture.

### Follow-up applied

Date: 2026-06-03

Root cause: the smoke runner waited for final mailbox/UI outcomes without first checking the provider receiving boundary, so a DNS/Postmark receiving failure looked like a long generic smoke-test timeout.

Fix applied:

- `smoke-tests/lib/postmark.js`: added optional Postmark inbound message-history diagnostics using the server token and `/messages/inbound` query.
- `smoke-tests/lib/config.js` and `smoke-tests/features/support/world.js`: added optional `MEMBA_SMOKE_POSTMARK_SERVER_TOKEN` / `MEMBA_SMOKE_POSTMARK_INBOUND_MESSAGE_STREAM` configuration and wired the diagnostics client into the Cucumber world.
- `smoke-tests/features/step_definitions/inbound_club_email_steps.js`: after SMTP acceptance, each inbound scenario now checks whether Postmark received the exact subject/recipient before waiting for Memba-visible outcomes when a Postmark token is configured.
- `smoke-tests/README.md` and `smoke-tests/features/inbound_club_email.feature`: documented the optional Postmark boundary check and corrected the smoke club name to `Smoke Test Club`.

Validation:

- `node --check smoke-tests/lib/config.js && node --check smoke-tests/lib/postmark.js && node --check smoke-tests/features/support/world.js && node --check smoke-tests/features/step_definitions/inbound_club_email_steps.js` — passed.
- `cd smoke-tests && npm test -- --dry-run` — passed; Cucumber discovered 3 scenarios and 21 steps.
- `dev check` — blocked because an existing local Phoenix/test process has 52 open `memba_test` database sessions, so the test database cannot be dropped. I did not stop the user's running server/processes.

Remaining follow-up:

- Run the production smoke tests with `MEMBA_SMOKE_POSTMARK_SERVER_TOKEN` set to distinguish provider receiving failure from webhook/application failure.
- If Postmark receives the message but Memba still has no visible outcome, add webhook delivery diagnostics as the next boundary check.

### Production smoke completion

Date: 2026-06-03

Root cause: the production cutover still had two independent problems after the smoke runner existed. First, the Postmark `memba.io` server inbound hook was configured as `/webhooks/postmark` instead of the inbound-email route `/webhooks/postmark/inbound`. Second, Postmark rejected inbound rejection emails because the Postmark metadata keys for inbound rejection emails exceeded Postmark's 20-character metadata-key limit.

Fix applied:

- Postmark production configuration: updated the `memba.io` server inbound hook URL to `https://memba.io/webhooks/postmark/inbound`.
- `web/lib/memba/messaging/inbound_club_rejection_email.ex`: shortened Postmark metadata keys for inbound rejection emails and capped metadata values to Postmark's 80-character value limit.
- `web/test/memba/messaging/inbound_club_message_acceptance_test.exs`: updated the Postmark rejection-email metadata expectation.
- `smoke-tests/lib/browser.js`: made staff sign-in navigate explicitly to `/admin/clubs` after following the magic link, instead of assuming the auth callback lands on an admin page, and made message visibility polling reload the club page between checks.
- `smoke-tests/lib/config.js`, `smoke-tests/lib/smtp.js`, `smoke-tests/lib/fastmail_imap.js`, and `smoke-tests/features/step_definitions/inbound_club_email_steps.js`: generalized SMTP/IMAP configuration so the smoke runner can use external Hotmail/Yahoo unknown-sender accounts.
- `smoke-tests/README.md`: documented the club-site base domain and external unknown-sender SMTP/IMAP configuration.
- Deployed the metadata fix to Fly app `memba` with `fly deploy -a memba --remote-only`.

Validation:

- `bin/mix test test/memba/messaging/inbound_club_message_acceptance_test.exs` — passed; 14 tests, 0 failures.
- `dev check` — passed; 495 ExUnit tests and 34 acceptance scenarios.
- `fly deploy -a memba --remote-only` — completed successfully; release command reported migrations already up.
- Production smoke after changing Fastmail's `memba.io` subdomain routing to route mail externally — passed for the rejection scenarios and Postmark/Memba recorded the accepted member-message scenario through the public `test@clubs.memba.io` path. The smoke runner's member-visible UI polling was then tightened to reload while waiting for asynchronous delivery.

Remaining follow-up:

- Add the Hotmail/Yahoo mailbox credentials to `.local/secrets.envrc` when the 1Password CLI can access Matt's Wynne Family vault, then run `bin/dev smoke-test` using one of those external accounts as the unknown sender.

### Follow-up decision

Date: 2026-06-04

This remaining follow-up was deliberately abandoned. Hotmail's IMAP/SMTP endpoints were reachable, but basic username/password authentication was blocked (`BasicAuthBlocked` on IMAP and `535 5.7.3 Authentication unsuccessful` on SMTP). Yahoo was also not working reliably enough to use now.

ADR 0020 records the replacement decision: keep the smoke runner Fastmail-only and use an unregistered Fastmail alias for the unknown-sender case, rather than expanding production smoke tests into arbitrary consumer-mailbox automation.
