1. **Selected todo line**
   - `009 Update browser acceptance support, if needed, so existing member-message scenarios can find addressed recipient rows by expanding the relevant visible group before asserting row content. Do not change the Gherkin feature text for this iteration.`

2. **Changes made**
   - Updated `acceptance-tests/features/support/member_message.js`:
     - Added support helper to expand collapsed member receipt groups via existing LiveView group toggle buttons before checking member receipt rows.
     - Made addressed-recipient count waiting projection-aware, so it can retry expansion if receipt groups appear after the page first loads.
     - Applied the expansion helper to member-facing addressed-member and receipt-status assertions.
   - Updated `acceptance-tests/test/member_message_steps.test.js`:
     - Extended the fake Playwright page/locator test harness for collapsed group toggles.
     - Added regression coverage proving member receipt assertions expand collapsed groups before inspecting rows.
   - Did **not** change any `.feature` files.

3. **Focused validation**
   - `cd acceptance-tests && npm_config_cache=/tmp/npm-cache npm ci`
     - Passed, installed browser acceptance dependencies locally.
   - `cd acceptance-tests && npm_config_cache=/tmp/npm-cache npm run test:config`
     - Passed: `37 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `228 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 009 Update browser acceptance support, if needed, so existing member-message scenarios can find addressed recipient rows by expanding the relevant visible group before asserting row content. Do not change the Gherkin feature text for this iteration.`
   - To:
     - `- [x] 009 Update browser acceptance support, if needed, so existing member-message scenarios can find addressed recipient rows by expanding the relevant visible group before asserting row content. Do not change the Gherkin feature text for this iteration.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0003 / ADR 0010: Kept shared Gherkin feature files unchanged and moved UI mechanics into browser support code.
   - ADR 0013: Added/updated feature-style browser support tests around the acceptance helper behavior.
   - ADR 0006 / ADR 0015: Preserved simplified member-facing receipt status assertions and worked with the LiveView expand/collapse UI instead of bypassing it.