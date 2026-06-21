Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `008 After integrating with 041's result, update reply notification email Reply-To / reply destination generation to use the new address while preserving 041's Message-ID / In-Reply-To / References header behaviour.`

2. **Changes made**
   - Added focused regression coverage in:
     - `web/test/memba/messaging/member_message_email_test.exs`
   - The test proves reply notifications:
     - use `Reply-To: {"Kootenay Mountaineering Club", "everyone@kmc.clubs.memba.io"}`;
     - do not use the old flat `kmc@clubs.memba.io`;
     - preserve the 041 `Message-ID` generation;
     - preserve `In-Reply-To` and `References` threading headers.

3. **Validation run**
   - Formatting:
     - `PATH="$PWD/bin:$PATH:$PWD/.devenv/profile/bin" PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 bin/mix format --check-formatted test/memba/messaging/member_message_email_test.exs`
     - Passed.
   - Focused reply-email tests:
     - `PATH="$PWD/bin:$PATH:$PWD/.devenv/profile/bin" PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 bin/mix test test/memba/messaging/member_message_email_test.exs test/memba/messaging/email_delivery_providers/local_test.exs test/memba/messaging/email_delivery_providers/postmark_test.exs test/memba/messaging/email_delivery_providers/resend_test.exs`
     - Passed: `21 tests, 0 failures`.
   - I also attempted:
     - `PATH="$PWD/bin:$PATH:$PWD/.devenv/profile/bin" dev check --quick`
     - It failed in still-pending domain/acceptance plumbing related to unchecked later tasks, especially old inbound address support in reply-by-email step helpers. I did not expand this task into task 010.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 008 After integrating with 041's result, update reply notification email ...`
   - To:
     - `- [x] 008 After integrating with 041's result, update reply notification email ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007 preserved: no Membership/Messaging boundary changes; reply email rendering still consumes projected/request data.
   - ADR 0016 preserved: provider-specific delivery remains behind existing provider modules; the shared `MemberMessageEmail` boundary stays provider-neutral.
   - ADR 0013 not implicated by this non-web unit coverage; no feature files were edited.