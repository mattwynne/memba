Implemented next unchecked task: `015 Remove or narrow @todo-domain/@todo-ui from club_member_invitations.feature once implemented.`

1. **Selected todo line**
   - `- [ ] 015 Remove or narrow @todo-domain/@todo-ui from club_member_invitations.feature once implemented.`

2. **Changes made**
   - Narrowed `acceptance-tests/features/club_member_invitations.feature`:
     - Removed feature-level `@todo-domain @todo-ui`.
     - Kept current Staff invitation scenarios executable under `@iteration-028`.
     - Added `@todo-domain @todo-ui` only to the future `@iteration-029` Membership Admin invitation scenarios.
   - Updated `acceptance-tests/test/cucumber_config.test.js` so `club_member_invitations.feature` is now expected in the default browser-selected feature list.
   - Checked off task `015` in `docs/iterations/028-staff-member-invitations/todo.md`.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" npm test --prefix acceptance-tests -- --dry-run`
     - Passed: `69 scenarios (69 skipped)` discovered/selected.
   - `PATH="$PWD/bin:$PATH" node --test acceptance-tests/test/cucumber_config.test.js`
     - Passed: `4 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/features/cucumber_configuration_test.exs test/features/domain_cucumber_runner_test.exs`
     - Passed: `5 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/features/domain_cucumber_acceptance_test.exs`
     - Passed: `54 tests, 0 failures`.
   - Targeted browser Cucumber for `club_member_invitations.feature` via temporary config inside `devenv shell`
     - Passed: `7 scenarios, 45 steps passed`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - `721 tests, 0 failures`
       - `69 scenarios, 466 steps passed`

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 015 Remove or narrow ...`
   - To:
     - `- [x] 015 Remove or narrow ...`

5. **Todo splits/additions/reordering**
   - None. Task `016` remains unchecked.

6. **ADR / plan conformance**
   - No ADRs were explicitly referenced by this plan.
   - Conforms to the plan’s “Allowed acceptance feature changes” section: `club_member_invitations.feature` may remove or narrow `@todo-domain`/`@todo-ui` once Staff invitation/profile-completion behaviour is implemented.
   - Future Membership Admin scenarios remain deferred with `@iteration-029 @todo-domain @todo-ui`, matching the plan’s out-of-scope decision for this slice.