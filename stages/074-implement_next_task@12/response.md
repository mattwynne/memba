Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 012 Implement or update Cucumber step definitions only as needed during delivery to exercise the new @iteration-029 scenarios.`

2. **Changes made**
   - Updated Elixir/domain Cucumber steps:
     - `web/test/features/step_definitions/club_member_invitation_steps.exs`
     - Added Membership Admin setup.
     - Added ordinary-member assertion.
     - Added unauthorized invitation attempt/assertion steps.
     - Made invitation attempts actor-aware: Staff/system actors still use the shared invitation lifecycle directly; club members must have `club.manage_members`.
   - Updated browser Cucumber steps:
     - `acceptance-tests/features/step_definitions/club_member_invitation_steps.js`
     - Added missing `@iteration-029` step bindings.
     - Avoided ambiguity between inviting a named person and inviting a quoted email.
   - Updated browser invitation support:
     - `acceptance-tests/features/support/club_member_invitations.js`
     - Membership Admin actors now use the member-facing `/members/invitations/new` route on the club subdomain.
     - Ordinary-member direct attempts record/assert 403 rejection and no invitation email.
     - Existing Staff invitation helpers remain supported.
   - Updated todo:
     - `docs/iterations/029-membership-admin-invitations/todo.md`

3. **Validation run**
   - `node --check acceptance-tests/features/step_definitions/club_member_invitation_steps.js && node --check acceptance-tests/features/support/club_member_invitations.js`
     - Passed.
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/features/step_definitions/club_member_invitation_steps.exs`
     - Passed.
   - Cucumber JS dry-run for `@iteration-029` with default todo filters bypassed:
     - Passed with no undefined/ambiguous steps: `4 scenarios`, `23 steps`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.
     - Browser acceptance portion ended with `69 scenarios (69 passed), 466 steps (466 passed)`.
   - `git diff --check`
     - Passed.

4. **Exact todo check-off**
   - Changed only:
     - `- [ ] 012 Implement or update Cucumber step definitions only as needed during delivery to exercise the new @iteration-029 scenarios.`
   - To:
     - `- [x] 012 Implement or update Cucumber step definitions only as needed during delivery to exercise the new @iteration-029 scenarios.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0003 / ADR 0010: kept shared feature files unchanged and added execution plumbing for both domain Cucumber and browser Cucumber layers.
   - ADR 0019: browser Membership Admin invitation support uses club subdomain URLs via `clubSiteUrl(...)` rather than query-string-only routing.
   - No feature tags were removed in this task; that remains task 013.