Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `023 Keep all new acceptance scenarios tagged @wip until delivery implements the required step support and application behaviour.`

2. **Changes made**
   - Updated `acceptance-tests/test/cucumber_config.test.js`.
   - Added a focused config test that:
     - locates the seven inbound club-email scenarios in `member_message_deliverability.feature`;
     - asserts each remains tagged `@wip`;
     - asserts each is excluded by the default browser Cucumber profile (`not @todo-web and not @wip`).
   - Did **not** modify any `.feature` files.

3. **Validation run**
   - `cd acceptance-tests && npm run test:config -- test/cucumber_config.test.js`
     - Passed: `47 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed ExUnit: `470 tests, 0 failures`.
     - Passed browser acceptance: `31 scenarios, 31 passed`, `205 steps, 205 passed`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 023 Keep all new acceptance scenarios tagged \`@wip\` until delivery implements the required step support and application behaviour.`
   - To:
     - `- [x] 023 Keep all new acceptance scenarios tagged \`@wip\` until delivery implements the required step support and application behaviour.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan did not explicitly reference ADR files, and no `docs/adr/` entries were present.
   - The change preserves the shared feature file as the behaviour contract and adds only configuration-test enforcement.
   - The `@wip` deferral remains explicit and runner-enforced, matching the local acceptance guidance that future-facing planning scenarios are excluded by default until intentionally enabled.