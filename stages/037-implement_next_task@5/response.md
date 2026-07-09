1. **Selected todo line**
   - `005 Add/update acceptance and unit test coverage for participant ordering, the overflow count, and the no-replies-yet case.`

2. **Changes made**
   - Added three `@iteration-051` scenarios to `acceptance-tests/features/club_message_replies.feature` under the allowed club-home conversation rule:
     - no replies → no participant avatar-stack;
     - distinct repliers shown in first-reply order, with originator excluded and duplicate repliers de-duplicated;
     - 4 distinct repliers → first 3 shown plus `+1`.
   - Added domain Cucumber step support in `web/test/features/step_definitions/messaging_steps.exs` for:
     - no participant avatars;
     - participant avatar-stack expected visible participants plus optional overflow count.
   - Updated `web/test/memba_web/live/member_dashboard_live_test.exs` to assert:
     - rendered participant avatar order;
     - no participant avatar-stack for a no-replies row.

3. **Validation commands/results**
   - `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs test/memba_web/member_dashboard_presentation_test.exs test/memba/messaging/message_projection_test.exs`
     - Passed: `43 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev test test/features/domain_cucumber_acceptance_test.exs --only scenario_name:"More than three distinct repliers show an overflow count"`
     - Passed: `1 test, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev test test/features/domain_cucumber_acceptance_test.exs --only scenario_name:"A conversation with no replies shows no participant avatar-stack" --only scenario_name:"Participant avatar-stacks show distinct repliers in first-reply order"`
     - Passed: `2 tests, 0 failures`.
   - `cd web && mix format --check-formatted test/features/step_definitions/messaging_steps.exs test/features/step_definitions/membership_steps.exs test/memba_web/live/member_dashboard_live_test.exs`
     - Passed.
   - Final exact-state validation: `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including browser acceptance: `88 scenarios (88 passed)`, `541 steps (541 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Add/update acceptance and unit test coverage for participant ordering, the overflow count, and the no-replies-yet case.`
   - to:
     - `- [x] 005 Add/update acceptance and unit test coverage for participant ordering, the overflow count, and the no-replies-yet case.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan references no ADRs.
   - `docs/adr/**/*` is empty in this checkout.
   - Followed local project guidance for Cucumber acceptance coverage and LiveView tests; preserved existing feature tags/rules/scenarios and added only the allowed `@iteration-051` scenarios.