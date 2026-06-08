Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `013 Remove or narrow @todo-domain/@todo-ui tags from the affected scenarios only when they pass in the relevant runner.`

2. **Changes made**
   - Updated `acceptance-tests/features/club_member_invitations.feature`:
     - Removed `@todo-domain` from all four `@iteration-029` scenarios because the domain runner passed all four.
     - Removed `@todo-ui` from the three `@iteration-029` scenarios that passed browser acceptance:
       - `Alice cannot invite someone to join West Coast Paddlers`
       - `Robin cannot invite an active member again`
       - `Robin resends a pending invitation by inviting the same email again`
     - Kept `@todo-ui` on:
       - `Robin invites Dana to join West Coast Paddlers`
       - Reason: direct browser run still fails at `Dana should be an ordinary member of West Coast Paddlers`.
   - Updated `docs/iterations/029-membership-admin-invitations/todo.md` to check off task `013` only.

3. **Validation commands/results**
   - Temporary focused domain run for `@iteration-029` with `@todo-domain` exclusion bypassed:
     - Passed: `0 failures`
   - Temporary focused browser run for `@iteration-029` with `@todo-ui` exclusion bypassed:
     - Result: `4 scenarios`, `3 passed`, `1 failed`
     - Failure was the Dana ordinary-member UI assertion, so that scenario kept `@todo-ui`.
   - After tag narrowing:
     - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/features/domain_cucumber_runner_test.exs test/features/domain_cucumber_acceptance_test.exs`
       - Passed: `60 tests, 0 failures`
     - `PATH="$PWD/bin:$PATH" dev acceptance -- features/club_member_invitations.feature`
       - Passed under default filters: `72 scenarios, 479 steps passed`
     - `PATH="$PWD/bin:$PATH" dev check`
       - Passed: `746 tests, 0 failures`; browser acceptance `72 scenarios, 479 steps passed`
     - `git diff --check`
       - Passed

4. **Todo check-off made**
   - Changed:
     - `- [ ] 013 Remove or narrow ...`
   - To:
     - `- [x] 013 Remove or narrow ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - No `docs/adr/*.md` files are present.
   - The feature-file edit is explicitly allowed by the iteration plan’s “Allowed acceptance feature changes” section.
   - Tags were removed/narrowed only where the corresponding runner passed; the failing browser scenario remains protected with `@todo-ui`.