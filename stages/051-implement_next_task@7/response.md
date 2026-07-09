Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `007 Update/remove the named acceptance scenarios and any unit test assertions tied to the removed elements; add coverage for the new preview text.`

2. **Changes made**
   - Updated `acceptance-tests/features/club_message_replies.feature`
     - Added `@iteration-050 @not-domain` browser scenarios covering:
       - club-home conversation preview text from the original message body;
       - absence of the "Recent club messages" heading;
       - absence of conversation entry badges;
       - absence of the duplicate sender meta line.
     - Moved the existing non-browser conversation scenarios behind `@not-ui` rule tags so the browser runner only picks up the new UI scenarios.
   - Updated `acceptance-tests/features/list_members.feature`
     - Added an `@iteration-050 @not-domain` browser scenario covering:
       - absence of the "Current members" heading;
       - exactly one visible "Invite member" action for a member who can manage members.
   - Added JS Cucumber step/support coverage in:
     - `acceptance-tests/features/step_definitions/member_message_steps.js`
     - `acceptance-tests/features/support/member_message.js`
     - `acceptance-tests/features/step_definitions/list_members_steps.js`
     - `acceptance-tests/features/support/list_members.js`
   - Checked off task `007` in `docs/iterations/050-club-home-conversation-and-member-row-fidelity/todo.md`.

3. **Validation run**
   - `cd acceptance-tests && npx cucumber-js --dry-run --tags "@iteration-050 and not @not-ui and not @todo-ui"`
     - Passed dry-run: `3 scenarios`, `24 steps`, no undefined steps.
   - `PATH="$PWD/bin:$PATH" dev test test/features/domain_cucumber_runner_test.exs test/features/domain_cucumber_acceptance_test.exs test/memba_web/live/member_dashboard_live_test.exs test/memba_web/controllers/member_message_detail_test.exs`
     - Passed: `126 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev acceptance`
     - Passed: `90 scenarios (90 passed), 560 steps (560 passed)`.
   - Final validation after todo check-off:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `90 scenarios (90 passed), 560 steps (560 passed)`.

4. **Exact todo check-off**
   - Changed only:
     - `- [ ] 007 Update/remove the named acceptance scenarios and any unit test assertions tied to the removed elements; add coverage for the new preview text.`
   - To:
     - `- [x] 007 Update/remove the named acceptance scenarios and any unit test assertions tied to the removed elements; add coverage for the new preview text.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No ADR files were present under `docs/adr/`, and the plan did not explicitly reference ADR files.
   - The changes stay within the approved presentation/acceptance-test scope:
     - no domain workflow changes;
     - browser-facing scenarios are tagged `@not-domain`;
     - previously domain-oriented conversation scenarios remain excluded from the browser runner with `@not-ui`;
     - existing LiveView/Phoenix coverage from prior tasks remains intact.