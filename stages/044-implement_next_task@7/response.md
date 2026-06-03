Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `022 Update browser acceptance step support only as needed to express the new @wip scenarios after implementation begins.`

2. **Changes made**
   - Updated browser Cucumber step definitions in:
     - `acceptance-tests/features/step_definitions/member_message_steps.js`
   - Added browser acceptance support helpers in:
     - `acceptance-tests/features/support/member_message.js`
   - Added support/unit coverage in:
     - `acceptance-tests/test/member_message_steps.test.js`
   - New support covers:
     - posting simulated Resend `email.received` inbound webhook payloads to `/webhooks/resend/inbound`;
     - accepted inbound messages being discoverable from member-facing club/message pages;
     - alternate sender address scenarios via existing shared person-email step support;
     - attachment and HTML-only rejection examples;
     - asserting no club message was created;
     - asserting rejection emails and support guidance in the Swoosh test mailbox;
     - asserting stripped/normalized member message body text.
   - Did **not** edit feature files.

3. **Validation commands run**
   - `cd acceptance-tests && npm run test:config -- test/member_message_steps.test.js`
     - Passed: `46 tests, 0 failures`.
   - `cd acceptance-tests && npm test -- --dry-run features/member_message_deliverability.feature`
     - Passed dry-run with no undefined/ambiguous step definitions.
   - Temporary `@wip`-only Cucumber dry-run:
     - `cd acceptance-tests && npx cucumber-js --config .tmp-cucumber-wip.cjs`
     - Passed: `7 scenarios`, `70 steps`, no undefined/ambiguous steps.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `470 tests, 0 failures`
       - Browser acceptance: `31 scenarios, 31 passed`, `205 steps, 205 passed`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 022 Update browser acceptance step support only as needed to express the new @wip scenarios after implementation begins.`
   - To:
     - `- [x] 022 Update browser acceptance step support only as needed to express the new @wip scenarios after implementation begins.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0003 / 0010: Kept shared feature files as the behaviour contract and added browser-layer step/support plumbing for existing shared scenarios.
   - ADR 0013: Browser support remains feature-style/user-visible, using Playwright/Cucumber support helpers rather than lower-level app internals.
   - ADR 0016: Resend-specific inbound webhook simulation stays isolated in acceptance support while domain behaviour remains provider-neutral in the app.
   - Acceptance feature edit rule respected: no `*.feature` files were changed.