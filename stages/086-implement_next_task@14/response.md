1. **Selected todo line**
   - `012 Implement or update Cucumber step definitions only as needed during delivery to exercise the new @iteration-029 scenarios.`

2. **Changes made**
   - Updated `web/test/features/step_definitions/membership_administration_steps.exs`
     - Added step wording for:
       - `Robin is a Membership Admin of West Coast Paddlers`
   - Updated `web/test/features/step_definitions/club_member_invitation_steps.exs`
     - Made invitation steps actor-aware:
       - Staff/system actors keep using `Membership.invite_club_member/2`.
       - Known non-staff club actors use `Membership.invite_club_member_as_club_member/2`.
     - Added step support for:
       - Membership Admin invitation attempts by email.
       - Ordinary-member unauthorized invitation attempts.
       - “should not receive an invitation” assertions.
       - “should be an ordinary member” assertions.
     - Preserved existing Staff invitation scenario behavior.
   - Updated `docs/iterations/029-membership-admin-invitations/todo.md`
     - Checked off task 012 only.

3. **Focused validation commands run**
   - Formatting:
     - `cd web && PATH="$PWD/../bin:$PATH" ../bin/mix format --check-formatted test/features/step_definitions/club_member_invitation_steps.exs test/features/step_definitions/membership_administration_steps.exs`
     - Passed.
   - Existing domain Cucumber/step tests:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && MIX_ENV=test ../bin/mix test test/features/domain_cucumber_acceptance_test.exs test/features/membership_administration_steps_test.exs test/features/domain_cucumber_runner_test.exs'`
     - Passed: `60 tests, 0 failures`.
   - Final direct `@iteration-029` domain scenario execution, one scenario per fresh test process:
     - `Robin invites Dana to join West Coast Paddlers` — passed.
     - `Alice cannot invite someone to join West Coast Paddlers` — passed.
     - `Robin cannot invite an active member again` — passed.
     - `Robin resends a pending invitation by inviting the same email again` — passed.
   - Full quality gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `740 tests, 0 failures`
       - Browser acceptance: `69 scenarios, 466 steps passed`
   - Whitespace:
     - `git diff --check`
     - Passed.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 012 Implement or update Cucumber step definitions only as needed during delivery to exercise the new @iteration-029 scenarios.`
   - To:
     - `- [x] 012 Implement or update Cucumber step definitions only as needed during delivery to exercise the new @iteration-029 scenarios.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADRs were explicitly referenced by this iteration plan.
   - Local Cucumber documentation was consulted.
   - Acceptance feature files were not edited for this task; only step-definition plumbing was added as allowed by the plan.
   - The implementation exercises the approved Membership Admin invitation scenarios while preserving Staff invitation behavior.