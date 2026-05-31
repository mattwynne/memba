1. **Selected todo line**
   - `005 Implement member-message browser steps by driving /clubs, /clubs/:club_id, and /messages/:message_id through accessible labels, roles, and stable identifiers supplied by the existing UI.`

2. **Changes made**
   - Added `acceptance-tests/features/support/member_message.js`
     - Browser helpers for:
       - creating clubs via `/clubs`;
       - creating people via `/clubs/:club_id`;
       - adding members via `/clubs/:club_id`;
       - sending Kootenay club messages via `/clubs/:club_id`;
       - opening `/messages/:message_id`;
       - asserting addressed recipients, delivery records, email-channel delivery, and member receipt status from visible UI rows.
     - Stores generated `club_id`, `person_id`, `member_id`, `message_id`, and `delivery_id` values from existing DOM data attributes.
     - Uses accessible labels/roles for form interaction and stable `data-testid`/`data-*` attributes for projected rows.
   - Added `acceptance-tests/features/step_definitions/member_message_steps.js`
     - Implements the member-message background setup steps.
     - Implements message sending and message projection assertion steps.
     - Implements member receipt status assertion steps.
     - Leaves webhook/status-change steps for task 006.
   - Added `acceptance-tests/test/member_message_steps.test.js`
     - Covers route URL construction, email generation, UI-driving helper behavior, scenario state tracking, and message assertion helpers.
   - Updated `docs/iterations/006-browser-cucumber-automation/todo.md`
     - Checked off only task 005.

3. **Focused validation**
   - `cd acceptance-tests && npm run test:config`
     - Passed: 13 tests, 0 failures.
   - `cd acceptance-tests && npm test -- --dry-run --name "A member sends a club message"`
     - Passed dry-run: all 11 steps matched.
   - `cd acceptance-tests && npm test -- --dry-run --name "A sent message is waiting for delivery confirmation"`
     - Passed dry-run: all 8 steps matched.
   - `cd acceptance-tests && npm test -- --dry-run --name "A delivered message is shown as delivered"`
     - Expected remaining undefined step is the webhook/status step for task 006.
   - `cd acceptance-tests && npm test -- --dry-run`
     - Shows remaining undefined steps only for later webhook/status and operator-specific work.
   - `cd acceptance-tests && npm test -- --name "A member sends a club message"`
     - Failed before scenario steps because the environment is missing the Playwright Chromium executable:
       - `browserType.launch: Executable doesn't exist ... Please run npx playwright install`
   - `git diff --check`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: 109 tests, 0 failures.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Implement member-message browser steps by driving /clubs, /clubs/:club_id, and /messages/:message_id through accessible labels, roles, and stable identifiers supplied by the existing UI.`
   - To:
     - `- [x] 005 Implement member-message browser steps by driving /clubs, /clubs/:club_id, and /messages/:message_id through accessible labels, roles, and stable identifiers supplied by the existing UI.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0003: kept shared feature files as the acceptance source and added only browser-layer cucumber-js/Playwright plumbing.
   - ADR 0010: did not change Elixir/domain Cucumber feature discovery or filtering; no `.feature` files were edited.
   - ADR 0013: did not alter PhoenixTest-based web-test architecture or production Phoenix code.
   - No production UI/routes/domain behavior were changed for this task.