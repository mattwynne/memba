Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `007 Add bounded polling/waiting around browser-visible projections after commands and webhook posts. Prefer Playwright assertions such as expect(...).toHaveText, expect.poll, or equivalent Cucumber helper retries over fixed sleeps.`

2. **Changes made**
   - Updated `acceptance-tests/features/support/member_message.js`
     - Added configurable bounded projection waits:
       - `ACCEPTANCE_PROJECTION_TIMEOUT_MS` / `world.projectionTimeoutMs`
       - `ACCEPTANCE_PROJECTION_POLL_INTERVAL_MS` / `world.projectionPollIntervalMs`
     - Wrapped command-result checks with bounded Playwright assertions for:
       - club rows
       - person rows
       - member rows
       - message rows
       - addressed recipient rows
       - delivery records
       - delivery status text
       - receipt rows/status text
     - Added webhook projection polling after `POST /webhooks/postmark`.
       - Status steps now wait until the browser-visible member receipt projection reaches the expected status.
       - Polling reloads the real message route until the projected UI is observable or the bounded timeout expires.
     - Added member-facing mapping for webhook events:
       - `delivered -> delivered`
       - `opened -> opened`
       - `delayed|bounced|spam_complaint -> delivery problem`
   - Updated `acceptance-tests/test/member_message_steps.test.js`
     - Added tests proving command projection waits use bounded Playwright timeouts.
     - Added tests proving webhook status reporting polls the browser-visible receipt projection.
     - Added tests for event-to-member-receipt-status mapping.
   - Updated `docs/iterations/006-browser-cucumber-automation/todo.md`
     - Checked off task `007` only.

3. **Focused validation**
   - `cd acceptance-tests && npm run test:config`
     - Passed: `19` tests, `0` failures.
   - `cd acceptance-tests && npm test -- --dry-run --name "A delivered message is shown as delivered"`
     - Passed dry-run: scenario matched, no undefined steps.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `109` tests, `0` failures.
   - `git diff --check`
     - Passed.
   - Also attempted focused real browser run:
     - `cd acceptance-tests && npm test -- --name "A delivered message is shown as delivered"`
     - Could not execute because the local Playwright Chromium executable is missing from the environment. This is an environment/browser-install issue, not an assertion/code failure.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 007 Add bounded polling/waiting around browser-visible projections after commands and webhook posts. Prefer Playwright assertions such as expect(...).toHaveText, expect.poll, or equivalent Cucumber helper retries over fixed sleeps.`
   - To:
     - `- [x] 007 Add bounded polling/waiting around browser-visible projections after commands and webhook posts. Prefer Playwright assertions such as expect(...).toHaveText, expect.poll, or equivalent Cucumber helper retries over fixed sleeps.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0003 / 0010: Kept shared `.feature` files unchanged; only browser-layer Cucumber/Playwright plumbing changed.
   - ADR 0004: Continued using message/delivery IDs exposed through the browser UI; no aggregate/model changes.
   - ADR 0006: Preserved accepted member-facing receipt vocabulary.
   - ADR 0009: Did not make projections strongly consistent; added harness-level bounded waits for eventual projection visibility.
   - ADR 0012: Preserved opened-status semantics and only waited for the browser-visible projected status.