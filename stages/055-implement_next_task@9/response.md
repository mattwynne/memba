1. **Selected todo line**
   - `009 Update tests, especially:`

2. **Changes made**
   - Expanded `web/test/memba/accounts/auth_email_test.exs`:
     - Resend auth sign-in now asserts subject, text body, HTML button/fallback/trust content, recipient footer, and no `help@memba.io`.
     - Local auth sign-in now asserts subject, text link, HTML link/button fallback, and provider options.
   - Expanded `web/test/memba/messaging/email_delivery_providers/resend_test.exs`:
     - Resend member-message tests now assert the v2 member-message HTML structure, escaped body, unchanged text body, reply guidance, carrier footer, tags, and headers.
     - Added header-sanitization coverage for sender/recipient/subject while preserving the exact text body.
   - Updated `web/lib/memba/messaging/email_delivery_providers/resend.ex` to use shared `Memba.Messaging.MemberMessageEmail` rendering/header helpers so the new Resend tests pass and Resend remains aligned with Postmark/local.
   - Expanded `web/test/memba/messaging/inbound_club_rejection_email_test.exs`:
     - Added fallback no-group/no-reply-to coverage for Memba-led subject, generic support next steps, sanitized original subject, escaped HTML body, metadata, and no hard-coded `help@memba.io`.

3. **Focused validation**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted lib/memba/messaging/email_delivery_providers/resend.ex test/memba/accounts/auth_email_test.exs test/memba/messaging/email_delivery_providers/resend_test.exs test/memba/messaging/inbound_club_rejection_email_test.exs`
     - Passed.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/accounts/auth_email_test.exs test/memba/onboarding/welcome_email_test.exs test/memba/messaging/email_delivery_providers/postmark_test.exs test/memba/messaging/email_delivery_providers/local_test.exs test/memba/messaging/email_delivery_providers/resend_test.exs test/memba/messaging/inbound_club_rejection_email_test.exs`
     - Passed: `31 tests, 0 failures`.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `585 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 009 Update tests, especially:`
   - To:
     - `- [x] 009 Update tests, especially:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0016 requires Resend to remain a first-class switchable provider with continued test coverage; the added Resend tests exposed and fixed provider drift by routing Resend member-message rendering through the same shared v2 helper path.
   - ADRs 0004–0006 messaging boundaries/status semantics remain unchanged: only email rendering/header safety/provider handoff tests and Resend rendering alignment changed.
   - No provider selection, DNS, sender-domain, authorization, inbound policy, or message-delivery domain rules were changed.