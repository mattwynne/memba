Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `007 Update/remove the named acceptance scenarios and any unit test assertions tied to the removed elements; add coverage for the new preview text.`

2. **Changes made**
   - Updated `acceptance-tests/features/club_message_replies.feature`
     - Added an `@iteration-050` club-home scenario covering:
       - conversation preview text from the original message body
       - absence of the “Recent club messages” heading
     - Added an `@iteration-050` conversation-page scenario covering:
       - no conversation entry kind badges
       - no duplicate `From Alice` line under the title
   - Updated `acceptance-tests/features/list_members.feature`
     - Added an `@iteration-050` Members tab scenario covering:
       - no “Current members” heading
       - exactly one visible “Invite member” action for a member who can manage members
   - Updated acceptance step definitions/support:
     - `acceptance-tests/features/step_definitions/member_message_steps.js`
     - `acceptance-tests/features/support/member_message.js`
     - `acceptance-tests/features/step_definitions/list_members_steps.js`
     - `acceptance-tests/features/support/list_members.js`
   - Existing Phoenix/LiveView unit coverage already covered the removed UI elements and new preview text from earlier completed tasks, so no additional web test changes were needed for this task.

3. **Validation run**
   - `cd acceptance-tests && npm test -- --dry-run --tags @iteration-050`
     - Passed dry-run for default executable `@iteration-050` coverage.
   - Temporary no-default-filter Cucumber dry-run for all `@iteration-050` scenarios:
     - Passed: `3 scenarios (3 skipped)`, `24 steps (24 skipped)`.
   - `PATH="$PWD/bin:$PATH" dev acceptance -- --tags @iteration-050`
     - Passed: `1 scenario (1 passed)`, `5 steps (5 passed)`.
   - Temporary no-default-filter acceptance run for all `@iteration-050` scenarios:
     - Passed: `3 scenarios (3 passed)`, `24 steps (24 passed)`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `88 scenarios (88 passed)`, `541 steps (541 passed)`.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 007 Update/remove the named acceptance scenarios and any unit test assertions tied to the removed elements; add coverage for the new preview text.`
   - To:
     - `- [x] 007 Update/remove the named acceptance scenarios and any unit test assertions tied to the removed elements; add coverage for the new preview text.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No ADRs were explicitly referenced by the iteration plan.
   - Followed the plan’s allowed acceptance feature change constraints:
     - Only added `@iteration-050` scenarios in the named feature files.
     - Did not retag, reorder, or modify unrelated existing scenarios/tags.
   - Followed local acceptance/Phoenix test guidance and ran full `dev check` because acceptance tests changed.