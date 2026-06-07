1. **Selected todo line**
   - `008 Update web/lib/memba/messaging/inbound_club_rejection_email.ex to use the new delivery-notice template, subject rules, reason copy, next-step copy, threading headers, and metadata.`

2. **Changes made**
   - Updated `Memba.Messaging.InboundClubRejectionEmail` to render the v2 Memba-led delivery notice template using `Memba.EmailTemplates`.
   - Added subject rules:
     - group-known: `Your email to {group} wasn't posted`
     - no group: `Your email wasn't posted`
     - threaded replies: sanitized `Re: {original subject}`
   - Added plain-language reason copy for all required rejection reasons.
   - Added next-step copy that uses configured Reply-To when present and avoids hard-coded `help@memba.io`.
   - Preserved Postmark metadata, Resend tags, and `X-Memba-*` headers.
   - Sanitized dynamic header values including group names, original subjects, and threading headers.
   - Added original-message context to text/HTML rejection notices.
   - Added focused test coverage in `web/test/memba/messaging/inbound_club_rejection_email_test.exs`.
   - Updated affected inbound acceptance/controller test expectations for the new copy and subjects.

3. **Focused validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted ...`
     - Passed.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba/messaging/inbound_club_rejection_email_test.exs test/memba/messaging/inbound_club_message_acceptance_test.exs test/memba_web/controllers/postmark_inbound_webhook_controller_test.exs test/memba_web/controllers/resend_inbound_webhook_controller_test.exs`
     - Passed: `36 tests, 0 failures`.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `583 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 008 Update web/lib/memba/messaging/inbound_club_rejection_email.ex ...`
   - To:
     - `- [x] 008 Update web/lib/memba/messaging/inbound_club_rejection_email.ex ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Reviewed relevant accepted messaging/provider ADRs:
     - ADR 0004, 0005, 0006, 0016.
   - Changes preserve existing message/rejection domain flow, provider switchability, Postmark metadata, Resend tags, threading headers, and delivery boundaries.
   - No provider configuration, DNS, sender-domain, authorization, or inbound policy changes were made.