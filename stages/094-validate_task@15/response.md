### Decision

**VALID**

### Evidence

- **Completed todo/check-off evidence found.**
  - Live `git status --short` and `git diff --stat` are clean.
  - `/tmp/fabro-pre-validate-snapshot.md` records a clean snapshot at `4c39f0a fabro(...): implement_next_task (succeeded)`.
  - Recent history shows `4c39f0a` as the implement checkpoint followed by `6bd2183` pre-validation.
  - `git diff 4c39f0a^ 4c39f0a -- docs/iterations/029-membership-admin-invitations/todo.md acceptance-tests/features/club_member_invitations.feature` shows exactly one ordinary todo changed from unchecked to checked:
    - `013 Remove or narrow @todo-domain/@todo-ui tags from the affected scenarios only when they pass in the relevant runner.`
  - Prior todo state had tasks through `012` checked and `013` as the first unchecked task.

- **Implementation artifacts found.**
  - `acceptance-tests/features/club_member_invitations.feature` was updated to remove `@todo-domain` from the four `@iteration-029` Membership Admin scenarios.
  - `@todo-ui` remains on those scenarios, preserving UI-runner deferral while enabling domain coverage.
  - This is concrete test/acceptance configuration evidence for the selected task, not a todo-only change.

- **Tests run/results found.**
  - Reran focused domain Cucumber/configuration tests:
    - `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && MIX_ENV=test ../bin/mix test test/features/domain_cucumber_acceptance_test.exs test/features/domain_cucumber_runner_test.exs test/features/cucumber_configuration_test.exs'`
    - Result: `63 tests, 0 failures`.
  - Reran focused JS Cucumber config tests:
    - `cd acceptance-tests && node --test test/cucumber_config.test.js`
    - Result: `4 tests`, all passed.
  - Repository remained clean after validation tests.

- **ADR/plan conformance notes.**
  - Plan explicitly permits edits to `acceptance-tests/features/club_member_invitations.feature` under `## Allowed acceptance feature changes`, including removing or narrowing `@todo-domain`/`@todo-ui` only when covered behaviour passes in the relevant runner.
  - The edit is limited to the named feature file and only narrows debt tags for the planned `@iteration-029` scenarios.
  - Keeping `@todo-ui` is plan-preserving because UI/browser coverage remains intentionally deferred until relevant runner support exists.
  - No plan-required scope was deleted, weakened, or silently deferred; task `014 Run dev check` remains unchecked for the next step.
  - Relevant shared-feature organization constraints are respected: feature file remains under `acceptance-tests/features/`.

{"context_updates":{"task_valid":true,"task_retry_available":false}}