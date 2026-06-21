Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `009 Update provider parser or provider-neutral inbound email tests where recipient-address normalization assumes the old flat address.`

2. **Changes made**
   - Updated provider parser tests to use the new address shape:
     - `web/test/memba_web/postmark_inbound_email_parser_test.exs`
     - `web/test/memba_web/resend_inbound_email_parser_test.exs`
   - Updated provider-neutral inbound email API normalization tests:
     - `web/test/memba/messaging/inbound_email_api_test.exs`
   - Replaced old flat examples like `kmc@clubs.memba.io` / `npc@clubs.memba.io` with:
     - `everyone@kmc.clubs.memba.io`
     - `everyone@npc.clubs.memba.io`
   - Strengthened the Postmark `OriginalRecipient` normalization fixture to cover display-name / angle-bracket / mixed-case input:
     - `KMC Everyone <Everyone@KMC.Clubs.Memba.IO>`
     - normalized to `everyone@kmc.clubs.memba.io`

3. **Focused validation**
   - Formatting passed:
     - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/memba_web/postmark_inbound_email_parser_test.exs test/memba_web/resend_inbound_email_parser_test.exs test/memba/messaging/inbound_email_api_test.exs`
   - Focused tests passed:
     - `PATH="$PWD/bin:$PATH:$PWD/.devenv/profile/bin" PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 bin/mix test test/memba_web/postmark_inbound_email_parser_test.exs test/memba_web/resend_inbound_email_parser_test.exs test/memba/messaging/inbound_email_api_test.exs`
     - Result: `19 tests, 0 failures`
   - Also attempted broad quick check:
     - `PATH="$PWD/bin:$PATH:$PWD/.devenv/profile/bin" PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 dev check --quick`
     - Result: failed with 2 failures in pending acceptance/domain plumbing, including reply-by-email step support still using old task-010 behavior. This is consistent with the next unchecked task and not caused by the parser/provider-neutral test updates.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 009 Update provider parser or provider-neutral inbound email tests where recipient-address normalization assumes the old flat address.`
   - To:
     - `- [x] 009 Update provider parser or provider-neutral inbound email tests where recipient-address normalization assumes the old flat address.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No acceptance feature files were edited.
   - Provider parsing remains provider-specific and translates into the existing provider-neutral `InboundEmail` API boundary.
   - No Membership/Messaging boundary changes or routing-policy changes were introduced; this task only updates tests to reflect the already-implemented new address convention.