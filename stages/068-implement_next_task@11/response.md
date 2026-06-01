1. **Selected todo line**
   - `011 Run the existing member-message browser Cucumber scenarios and dev check.`

2. **Changes made**
   - Fixed the browser acceptance support helper in `acceptance-tests/features/support/member_message.js`.
     - The helper could expand four collapsed receipt groups and then throw before doing a final “all groups expanded” recheck.
     - It now allows expanding up to the four valid visible member receipt groups and rechecks for remaining collapsed groups before failing.
   - Added focused JS support coverage in `acceptance-tests/test/member_message_steps.test.js`.
     - New test proves member receipt assertions can expand all four visible receipt groups before asserting a recipient row.
   - Did **not** modify any `.feature` files.

3. **Focused validation commands run**
   - `cd acceptance-tests && npm run test:config`
     - Passed: `38 tests, 0 failures`.
   - `cd acceptance-tests && npx cucumber-js --name "Alice sends a club message|Alice sees different receipt statuses for different members|Bob sees the same shared receipt statuses"`
     - Passed: `3 scenarios, 39 steps`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `230 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 011 Run the existing member-message browser Cucumber scenarios and \`dev check\`.`
   - To:
     - `- [x] 011 Run the existing member-message browser Cucumber scenarios and \`dev check\`.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0003 / ADR 0010: Kept shared Gherkin feature files unchanged; fixed executable browser support instead.
   - ADR 0006: Preserved member-facing simplified receipt statuses.
   - ADR 0013: Added focused browser-support test coverage for user-visible acceptance plumbing.
   - ADR 0015: Validated the LiveView member message receipt page through browser Cucumber scenarios and `dev check`.