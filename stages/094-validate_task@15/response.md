### Decision

**VALID**

### Evidence

- **Completed todo/check-off evidence found.**
  - Read `/tmp/fabro-pre-validate-snapshot.md`; it records a clean tree at implementation checkpoint `10a0f45`.
  - Live `git status --short` and `git diff` are clean; current HEAD is the later `pre_validate_snapshot` checkpoint `7073c65`.
  - `git show 10a0f45 -- docs/iterations/028-staff-member-invitations/todo.md` shows exactly one ordinary task changed:
    - `015 Remove or narrow @todo-domain/@todo-ui from club_member_invitations.feature once implemented.` from unchecked to checked.
  - `git show 10a0f45^:.../todo.md` confirms task `015` was the first unchecked task before the implementation checkpoint.

- **Implementation artifacts found.**
  - `10a0f45` changes:
    - `acceptance-tests/features/club_member_invitations.feature`
    - `acceptance-tests/test/cucumber_config.test.js`
    - `docs/iterations/028-staff-member-invitations/todo.md`
  - Feature-level `@todo-domain @todo-ui` was removed from `club_member_invitations.feature`.
  - Future Membership Admin scenarios remain deferred with scenario-level `@iteration-029 @todo-domain @todo-ui`.
  - Cucumber config test expectations were updated so `club_member_invitations.feature` is included in the default browser-selected feature list.

- **Tests run/results found.**
  - Live validation ran:
    - `PATH="$PWD/bin:$PATH" node --test acceptance-tests/test/cucumber_config.test.js`
      - Passed: `4 tests, 0 failures`.
    - `PATH="$PWD/bin:$PATH" npm test --prefix acceptance-tests -- --dry-run`
      - Passed dry-run discovery: `69 scenarios`, `466 steps`, all skipped as expected for dry-run.
  - Implementation summary also reports targeted Cucumber and full `dev check` passed.

- **ADR/plan conformance notes.**
  - The plan explicitly allows edits to `acceptance-tests/features/club_member_invitations.feature` to remove or narrow `@todo-domain`/`@todo-ui` once Staff invitation/profile-completion behaviour is implemented.
  - The edit preserves planned Staff coverage and keeps out-of-scope Membership Admin scenarios deferred.
  - No ADR constraints were found for this iteration.
  - No plan-required work was deleted, weakened, or silently deferred.
  - The checkpoint is small, focused, and independently useful.

{"context_updates":{"task_valid":true,"task_retry_available":false}}