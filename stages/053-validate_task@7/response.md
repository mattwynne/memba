### Decision
**HUMAN_INPUT**

### Evidence
- Completed todo/check-off evidence found:
  - Working tree is clean.
  - Latest artifact checkpoint is `5331e90 pre_validate_snapshot`; the implementation checkpoint is recent commit `c929963 fabro(...): implement_next_task`.
  - `c929963` changes exactly one ordinary todo line:
    - task `007 Update/remove the named acceptance scenarios...`
    - from `- [ ]` to `- [x]`.
  - Parent todo state had tasks `001`–`006` checked and `007` as the first unchecked task.

- Implementation artifacts found:
  - `acceptance-tests/features/club_message_replies.feature`
    - Adds `@iteration-050 @not-domain` UI scenarios for conversation preview, removed heading, removed badges, and removed duplicate sender meta.
    - Re-tags existing rules with `@not-ui`.
  - `acceptance-tests/features/list_members.feature`
    - Adds `@iteration-050 @not-domain` UI scenario for removed Members heading and one visible Invite action.
  - Adds/updates JS step and support code in:
    - `acceptance-tests/features/step_definitions/member_message_steps.js`
    - `acceptance-tests/features/support/member_message.js`
    - `acceptance-tests/features/step_definitions/list_members_steps.js`
    - `acceptance-tests/features/support/list_members.js`

- Tests run/results found:
  - Live validation dry-run passed:
    - `cd acceptance-tests && npx cucumber-js --dry-run --tags "@iteration-050 and not @not-ui and not @todo-ui"`
    - Result: `3 scenarios`, `24 steps`, no undefined steps.
  - Implementation summary reports focused tests, `dev acceptance`, and `dev check` passed, but I did not find durable repo test logs beyond that summary.

- ADR/plan conformance notes:
  - The implementation matches plan task `007` in substance.
  - ADR 0003/0010 support shared Cucumber feature files; the added `@not-domain` / `@not-ui` tagging appears intended to preserve runner boundaries.
  - However, the validation contract explicitly says acceptance feature files must not be edited unless the plan has a `## Allowed acceptance feature changes` section naming the exact file and allowed kind of change.
  - This plan names the feature files under `## Acceptance Scenarios / Feature Files`, but it does **not** contain a `## Allowed acceptance feature changes` section.
  - Live evidence shows two `*.feature` files were edited, so I cannot mark this valid under the stated validation gate.

### Human input
The plan explicitly asks for acceptance feature updates, but the validation gate requires a specifically titled `## Allowed acceptance feature changes` section before any `*.feature` edit is allowed. Should this plan’s `## Acceptance Scenarios / Feature Files` section be treated as sufficient permission, or should the plan be amended to add the required section before this task can be accepted?

{"context_updates":{"task_valid":false,"task_retry_available":false}}