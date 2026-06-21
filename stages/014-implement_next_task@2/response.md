Implemented the next unchecked task.

1. **Selected todo line**
   - `002 Update the inbound address helper so a club slug renders as everyone@<slug>.<configured inbound domain>, where the production/default inbound namespace remains clubs.memba.io.`

2. **Changes made**
   - Updated `Memba.ClubInboundEmailAddress.address/1` to return:
     - `everyone@kmc.clubs.memba.io`
     - `everyone@<slug>.<configured domain>`
   - Kept `ClubInboundEmailAddress.domain/0` environment-configurable with default `clubs.memba.io`.
   - Updated helper tests for:
     - default address generation;
     - slug normalization;
     - configured domain normalization/fallback.
   - Updated direct helper-consumer test expectations that now naturally render the new helper output:
     - member dashboard inbound email display/mailto;
     - member compose inbound email display/mailto;
     - local/Postmark/Resend reply-to assertions.
   - Checked off only todo item `002`.

3. **Focused validation run**
   - `bin/mix format ...` for touched Elixir files — passed.
   - Focused test run:
     - `mix test test/memba/club_inbound_email_address_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_message_live/new_test.exs test/memba/messaging/email_delivery_providers/postmark_test.exs test/memba/messaging/email_delivery_providers/local_test.exs test/memba/messaging/email_delivery_providers/resend_test.exs`
     - Result: `52 tests, 0 failures`.
   - `git diff --check` — passed.
   - `dev check --quick` was also run. The helper-related failures from the first run were resolved; the remaining output reports one `DomainCucumberRunnerTest` failure for a `@todo-domain` scenario selection that belongs to later task/tag-narrowing work.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 002 Update the inbound address helper ...`
   - To:
     - `- [x] 002 Update the inbound address helper ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Plan references no explicit ADRs.
   - Relevant current ADRs inspected:
     - ADR 0016: Resend remains a first-class switchable provider. I preserved provider boundaries and updated local/Postmark/Resend expectations consistently.
     - ADR 0019: Production club namespace remains `clubs.memba.io`; no conflict.
     - ADR 0020: Smoke-test architecture untouched; later task 012 handles smoke-test defaults.