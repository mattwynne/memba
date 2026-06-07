1. **Selected todo line**
   - `007 Update member-message delivery HTML in web/lib/memba/messaging/email_delivery_providers/postmark.ex and web/lib/memba/messaging/email_delivery_providers/local.ex, extracting shared rendering so both paths stay aligned. Keep plain-text member-message bodies exactly as the sender wrote them.`

2. **Changes made**
   - Added shared renderer: `web/lib/memba/messaging/member_message_email.ex`
     - Renders the v2 member-message HTML pattern:
       - group-led header;
       - sender-to-members line;
       - escaped plaintext message body converted to safe HTML;
       - reply guidance;
       - Memba carrier footer.
     - Provides shared sanitized header helpers for From, Reply-To, To, and Subject.
   - Updated Postmark and Local providers to use the shared renderer.
   - Preserved member-message `text_body` exactly as `request.body`.
   - Added optional `club_name` to `EmailDeliveryRequest`.
   - Populated `club_name` from `Membership.get_club/1` when sending club messages.
   - Updated focused tests for:
     - Postmark provider HTML/text/metadata/header sanitization.
     - Local provider HTML/text/metadata/local facts/header sanitization.
     - `send_club_message` delivery requests carrying club name.
     - Existing Postmark webhook metadata test expecting new HTML shape.

3. **Validation commands run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted ...`
     - Passed.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/messaging/email_delivery_providers/postmark_test.exs test/memba/messaging/email_delivery_providers/local_test.exs test/memba/messaging/send_club_message_test.exs test/memba_web/controllers/postmark_webhook_controller_test.exs`
     - Passed: `20 tests, 0 failures`.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `580 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 007 Update member-message delivery HTML ...`
   - To:
     - `- [x] 007 Update member-message delivery HTML ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No `docs/adr/*.md` files were present.
   - Changes stay within the iteration plan:
     - no provider configuration/DNS/sender-domain changes;
     - member-message From/Reply-To semantics preserved;
     - Postmark/local rendering now shared;
     - text member-message bodies remain exactly sender-authored;
     - dynamic sender/group/message content is escaped or header-sanitized.