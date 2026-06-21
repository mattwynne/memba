Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `010 Update acceptance step support to generate and submit new-address inbound webhook payloads; remove/narrow @todo-domain / @todo-ui tags as scenarios become executable.`

2. **Changes made**
   - Updated browser acceptance support:
     - `acceptance-tests/features/support/member_message.js`
       - Generates reply inbound addresses as `everyone@<club-slug>.<inbound-domain>`.
       - Uses `MEMBA_CLUB_INBOUND_EMAIL_DOMAIN` with default `clubs.memba.io`.
       - Extracts club slug from new subdomain-shaped inbound addresses.
     - `acceptance-tests/features/step_definitions/member_message_steps.js`
       - Added support for `replies by email ... through everyone@kmc.clubs.memba.io`.
       - Avoids rewriting the KMC slug for the explicit unknown-subdomain rejection scenario.
     - `acceptance-tests/test/member_message_steps.test.js`
       - Updated inbound webhook payload assertions to use `everyone@kmc.clubs.memba.io`.
   - Updated domain Cucumber step support:
     - `web/test/features/step_definitions/messaging_steps.exs`
       - Generalized inbound email steps from the old flat address to arbitrary addresses from the feature files.
       - Updated reply-by-email helper to default to `everyone@kmc.clubs.memba.io`.
       - Added missing domain steps needed by newly executable 042 scenarios.
   - Removed `@todo-domain` / `@todo-ui` from iteration-042 scenarios that are now executable in:
     - `acceptance-tests/features/member_message_deliverability.feature`
     - `acceptance-tests/features/club_message_replies.feature`
     - `acceptance-tests/features/email_branding.feature`

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/features/step_definitions/messaging_steps.exs` — passed.
   - `PATH="$PWD/bin:$PATH:$PWD/.devenv/profile/bin" PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 bin/mix test test/features/domain_cucumber_runner_test.exs test/features/cucumber_configuration_test.exs` — passed, `4 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH:$PWD/.devenv/profile/bin" PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 bin/mix test test/features/domain_cucumber_acceptance_test.exs` — passed, `83 tests, 0 failures`.
   - `cd acceptance-tests && node --test test/cucumber_config.test.js` — passed, `5 tests, 0 failures`.
   - `cd acceptance-tests && node --test --test-name-pattern "Resend inbound email payloads" test/member_message_steps.test.js` — passed, `1 test, 0 failures`.
   - `cd acceptance-tests && npm test -- --dry-run --tags "@iteration-042"` — passed, no undefined browser steps.
   - Staged the selected-task diff and ran:
     - `PATH="$PWD/bin:$PATH" dev check` — passed, including `85 scenarios (85 passed)`.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 010 Update acceptance step support to generate and submit new-address inbound webhook payloads; remove/narrow @todo-domain / @todo-ui tags as scenarios become executable.`
   - To:
     - `- [x] 010 Update acceptance step support to generate and submit new-address inbound webhook payloads; remove/narrow @todo-domain / @todo-ui tags as scenarios become executable.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0003 / ADR 0010: preserved shared feature files and made both domain and browser step support align with the same scenarios.
   - ADR 0016: kept inbound browser support on the existing provider-specific Resend webhook test seam while translating to the provider-neutral app behaviour.
   - No real external provider calls were introduced; acceptance remains fake/test-boundary driven.