### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found.
  - Read `/tmp/fabro-pre-validate-snapshot.md`: checkpoint `f0547d0` had clean status/diff.
  - Live `git status --short`, `git diff --stat`, and `git diff --check` are clean.
  - Recent commits show `f0547d0 fabro(...): implement_next_task (succeeded)` immediately before validation snapshot commit `93857ac`.
  - `git show f0547d0` shows exactly one ordinary todo line changed:
    - `013 Remove or narrow @todo-domain/@todo-ui tags...` from `- [ ]` to `- [x]`.
  - Parent todo state confirms task 013 was the first unchecked task; task 014 remains unchecked.

- Implementation artifacts found.
  - `acceptance-tests/features/club_member_invitations.feature`
    - Removed `@todo-domain @todo-ui` from the four `@iteration-029` Membership Admin invitation scenarios.
    - Preserved `@iteration-029` tags and scenario coverage.
  - `acceptance-tests/features/step_definitions/club_member_invitation_steps.js`
    - Added missing `assertActiveMember` import needed by the now-enabled ordinary-member assertion.
  - `docs/iterations/029-membership-admin-invitations/todo.md`
    - Checked off task 013 only.

- Tests run/results found.
  - Reran live focused browser validation:
    - `node --check acceptance-tests/features/step_definitions/club_member_invitation_steps.js`
    - `PATH="$PWD/bin:$PATH" dev acceptance --tags "@iteration-029"`
    - Result: `4 scenarios (4 passed), 23 steps (23 passed)`.
  - Reran live focused domain validation:
    - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/features/domain_cucumber_acceptance_test.exs --only domain_cucumber`
    - Result: `58 tests, 0 failures`.
  - Working tree remained clean after validation.

- ADR/plan conformance notes.
  - Plan task 013 specifically required removing/narrowing `@todo-domain`/`@todo-ui` only after scenarios passed; both relevant runners now pass.
  - The plan’s `## Allowed acceptance feature changes` explicitly names `acceptance-tests/features/club_member_invitations.feature` and allows this exact kind of tag removal.
  - ADR 0003 and ADR 0010 respected: shared Cucumber feature scenarios remain the shared behavioural contract and pass in both domain and browser layers.
  - ADR 0019 unaffected: no routing/subdomain strategy changes were made.
  - Scope stayed small and independently checkpointable; no plan-required work was deleted, weakened, or silently deferred.

{"context_updates":{"task_valid":true,"task_retry_available":false}}