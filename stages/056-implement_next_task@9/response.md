1. **Selected todo line**
   - `009 Remove @wip from member_message_deliverability.feature when browser scenarios pass.`

2. **Changes made**
   - Removed the `@wip` tag from `acceptance-tests/features/member_message_deliverability.feature`.
   - Fixed browser acceptance plumbing needed for the now-untagged scenarios:
     - member club-home helper now waits on stable `#member-club-home[data-club-id=...]` instead of expecting the club name to be a heading;
     - opened-email browser support now sends a delivered webhook first when needed, matching the domain transition rule.
   - Updated browser acceptance support tests/config expectations now that the member feature is selected by default.
   - Updated Elixir/domain Cucumber support so the now-shared untagged member feature passes through `dev check`:
     - added Dana background/member setup steps;
     - added member-facing assertion steps and member receipt label mapping;
     - added “has been reported…” delayed/bounced/opened variants;
     - made domain opened-email setup satisfy the delivered-before-opened transition.
   - Checked off only task `009` in `todo.md`.

3. **Focused validation run**
   - Before removing `@wip`, ran the member feature through browser Cucumber with a temporary config including `@wip`; fixed discovered failures, then:
     - `./node_modules/.bin/cucumber-js --config .tmp-cucumber-wip.js`
     - Result: `3 scenarios (3 passed), 39 steps (39 passed)`.
   - After removing `@wip`:
     - `cd acceptance-tests && npm run test:config && ./node_modules/.bin/cucumber-js features/member_message_deliverability.feature`
     - Result: `36` node tests passed; browser Cucumber reported `20 scenarios (20 passed), 144 steps (144 passed)`.
   - Full project gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Result: `217 tests, 0 failures`.
   - Whitespace:
     - `git diff --check`
     - Result: passed.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 009 Remove @wip from member_message_deliverability.feature when browser scenarios pass.`
   - To:
     - `- [x] 009 Remove @wip from member_message_deliverability.feature when browser scenarios pass.`

5. **Todo splits/additions/reordering**
   - None. Task `010 Run dev check` remains unchecked per ownership rules, even though I ran `dev check` as validation for this task.

6. **ADR conformance**
   - The plan did not explicitly reference any ADRs.
   - Changes preserve the shared acceptance-feature workflow: once `@wip` was removed, both browser Cucumber and the Elixir/domain runner were kept passing.
   - Member-facing assertions remain member-surface oriented; staff/operator diagnostic behaviour was not changed.