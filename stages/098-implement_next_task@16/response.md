Implemented the next unchecked task.

1. **Selected todo line**
   - `015 Update acceptance step support and remove the feature-level @wip tag from memba_staff_operations.feature once its scenarios pass.`

2. **Changes made**
   - Added `acceptance-tests/features/step_definitions/staff_operations_steps.js`
     - Browser acceptance steps for:
       - opening the staff area;
       - verifying working staff nav links: Clubs, People, Messages, Deliveries;
       - verifying Incoming/Roles are not offered;
       - opening global People and asserting Alice appears once with both club memberships;
       - opening global Messages and message diagnostics;
       - asserting staff delivery diagnostics are visible;
       - asserting staff club page has no send-club-message affordance.
   - Updated `acceptance-tests/features/memba_staff_operations.feature`
     - Removed only the feature-level `@wip` tag.
   - Updated `acceptance-tests/test/cucumber_config.test.js`
     - Default browser feature selection now includes `memba_staff_operations.feature`.
     - Skipped feature expectation now only includes `staff_club_slugs.feature`.
   - Updated `docs/iterations/021-staff-area-redesign/todo.md`
     - Checked off only task 015.

3. **Focused validation commands run**
   - `cd acceptance-tests && npm test -- --dry-run features/memba_staff_operations.feature`
     - Passed dry-run / no undefined-step failure.
   - `cd acceptance-tests && npm run test:config`
     - Passed: `48` node tests.
   - `PATH="$PWD/bin:$PATH" dev acceptance --name 'Pat opens the staff operations area|Alice belongs to two clubs|Pat opens diagnostics for an existing club message|Pat cannot send a club message from the staff club page'`
     - Passed: `4 scenarios, 37 steps`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `526 tests, 0 failures`
       - Browser acceptance: `38 scenarios, 252 steps`
   - `node --check acceptance-tests/features/step_definitions/staff_operations_steps.js`
     - Passed.
   - `git diff --check`
     - Passed.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 015 Update acceptance step support and remove the feature-level @wip tag from memba_staff_operations.feature once its scenarios pass.`
   - To:
     - `- [x] 015 Update acceptance step support and remove the feature-level @wip tag from memba_staff_operations.feature once its scenarios pass.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0003 / 0010: Kept the shared Cucumber feature as the acceptance contract and added browser-layer cucumber-js step support without duplicating feature files.
   - ADR 0013: Browser-facing behaviour is validated through feature-style web acceptance steps.
   - ADR 0007: Did not alter Membership/Messaging boundaries; acceptance setup uses existing support/server commands and UI routes only.