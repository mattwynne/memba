Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `018 Add/enable the planned Cucumber scenarios in acceptance-tests/features/person_email_addresses.feature; remove or narrow @wip once implemented.`

2. **Changes made**
   - Removed `@wip` from `acceptance-tests/features/person_email_addresses.feature`.
   - Added executable Cucumber step definitions for the planned person email-address scenarios in:
     - `acceptance-tests/features/step_definitions/person_email_address_steps.js`
   - Updated browser acceptance support to:
     - create/edit people with primary + alternate email addresses;
     - update person email-address sets through the staff UI;
     - assert primary/alternate display;
     - assert outbound club mail goes to primary and not alternate;
     - parse both current `/auth/sign-in/...` and legacy `/auth/magic/...` sign-in links.
   - Updated member-message steps so a sender like Bob is ensured as a Kootenay member when the scenario says Bob sends a club message.
   - Updated Cucumber config expectations now that `person_email_addresses.feature` is enabled.
   - Added acceptance scenario isolation via `/dev/test-support/reset` so globally unique email-address acceptance scenarios can run together without cross-scenario data conflicts.
   - Checked off only task `018` in `todo.md`.

3. **Validation run**
   - `cd acceptance-tests && node --test test/cucumber_config.test.js` — passed.
   - `cd acceptance-tests && node --test test/member_harness.test.js` — passed.
   - `cd acceptance-tests && node --test --test-name-pattern "creating people and members" test/member_message_steps.test.js` — passed.
   - `cd acceptance-tests && npx cucumber-js --dry-run --name "...person email address scenario names..." --format progress` — passed step-definition dry-run.
   - `cd acceptance-tests && PATH="$PWD/../bin:$PATH" npm test -- --name "...person email address scenario names..."` — passed: `4 scenarios, 23 steps`.
   - `cd web && mix format --check-formatted lib/memba_web/controllers/dev_test_support_controller.ex lib/memba_web/router.ex` — passed.
   - `git diff --check` — passed.
   - `dev check` — passed: `343 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 018 Add/enable the planned Cucumber scenarios...`
     - to:
     - `- [x] 018 Add/enable the planned Cucumber scenarios...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR / plan conformance**
   - No explicit ADR was referenced by the plan.
   - Feature edit was permitted by the plan’s “Allowed acceptance feature changes”.
   - The enabled scenarios cover the planned rules:
     - alternate email sign-in;
     - magic-link delivery to requested alternate;
     - club mail delivery to primary only;
     - staff create/edit of primary and alternate email addresses.