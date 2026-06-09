Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 008 Ensure the club-message rejection email uses the standard transactional email footer.`

2. **Changes made**
   - Confirmed from prior task 003 notes and current code that `Memba.Messaging.InboundClubRejectionEmail` already uses the canonical footer helper:
     - `Memba.EmailTemplates.memba_footer/1`
   - Added focused assertions in:
     - `web/test/memba/messaging/inbound_club_rejection_email_test.exs`
   - The tests now prove club-message rejection emails render the standard footer details:
     - “Delivered for <club> by Memba” with the `https://memba.io` link
     - recipient line
     - automatic delivery notice reason
     - reply-to support line when configured
     - generic support line when no reply-to is configured
     - no hard-coded `help@memba.io`

3. **Focused validation**
   - Focused test:
     - `devenv processes up --strict-ports -d postgres && devenv processes wait --timeout 120 && devenv shell -- bash -lc 'real_mix=$(which -a mix | grep -v "$(pwd)/bin/mix" | head -1); cd web; "$real_mix" test test/memba/messaging/inbound_club_rejection_email_test.exs'`
     - Result: `4 tests, 0 failures`
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: `757 tests, 0 failures`
   - Whitespace:
     - `git diff --check`
     - Result: passed

4. **Todo check-off made**
   - Changed exactly this line:
     - from `- [ ] 008 Ensure the club-message rejection email uses the standard transactional email footer.`
     - to `- [x] 008 Ensure the club-message rejection email uses the standard transactional email footer.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0016 respected: no email provider architecture changed.
   - Kept the existing Swoosh/Mailer path and provider-switchable configuration.
   - The task only added regression coverage around the existing shared `Memba.EmailTemplates.memba_footer/1` footer usage for rejection emails.