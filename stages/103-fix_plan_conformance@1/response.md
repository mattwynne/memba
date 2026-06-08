Implemented the plan-conformance repair and left the codebase passing `dev check`.

## 1. Plan requirement gap from the gate

The preceding gate did not expose a detailed textual repair brief in the prompt, but the current repository state showed one explicit plan-conformance gap:

- `acceptance-tests/features/club_member_invitations.feature` still had `@todo-ui` on the primary `@iteration-029` Membership Admin invitation scenario:
  - `Scenario: Robin invites Dana to join West Coast Paddlers`

This violated the plan’s delivery requirements to remove/narrow `@todo-domain`/`@todo-ui` tags once the affected scenarios pass.

## 2. Concrete changes made

### Requirement: Remove/narrow todo tags for passing `@iteration-029` scenarios

Changed:

- `acceptance-tests/features/club_member_invitations.feature`
  - Removed `@todo-ui` from `Scenario: Robin invites Dana to join West Coast Paddlers`.
  - The scenario is now included in the browser acceptance runner.

### Requirement: Make the now-unskipped browser scenario pass

After unskipping, the scenario exposed a test-support bug:

- The invitation scenario invited `dana@example.com`.
- The shared membership-administration assertion helper looked up `Dana` using the default generated email `dana@example.test`.
- This caused the ordinary-member assertion to check the wrong person.

Changed:

- `acceptance-tests/features/support/membership_administration.js`
  - Added `emailForPerson(world, personName)`.
  - Updated `ensureMember` and `memberStatus` to use the person email already remembered in Cucumber world state when present.
  - Preserves the existing generated-email fallback for scenarios that do not set a custom email.

No product code, migrations, config, or plan files were changed.

## 3. Files changed, grouped by requirement

### Remove todo tag / enable planned acceptance coverage

- `acceptance-tests/features/club_member_invitations.feature`

### Repair acceptance support for the enabled scenario

- `acceptance-tests/features/support/membership_administration.js`

## 4. Automated tests added or updated

- Updated the existing planned browser acceptance scenario by removing `@todo-ui`, so it now runs:
  - `@iteration-029 Scenario: Robin invites Dana to join West Coast Paddlers`

This scenario proves:

- A Membership Admin can invite by email.
- The invited person receives an invitation.
- The invited person is not active before acceptance.
- Unknown invitee supplies their name.
- Acceptance creates active ordinary membership.
- Invitee is signed in to the invited club.

## 5. Tests run and results

### Focused scenario after unskipping

Command:

```sh
PATH="$PWD/bin:$PATH" dev acceptance features/club_member_invitations.feature --tags @iteration-029 --name "Robin invites Dana"
```

Result:

- `1 scenario (1 passed)`
- `10 steps (10 passed)`

### All iteration-029 browser scenarios in affected feature

Command:

```sh
PATH="$PWD/bin:$PATH" dev acceptance features/club_member_invitations.feature --tags @iteration-029
```

Result:

- `4 scenarios (4 passed)`
- `23 steps (23 passed)`

### Full quality gate

Command:

```sh
PATH="$PWD/bin:$PATH" dev check
```

Result:

- ExUnit: `746 tests, 0 failures`
- Browser acceptance: `73 scenarios (73 passed)`, `489 steps (489 passed)`

## 6. Remaining plan gaps or human questions

None found.

Notes:

- `acceptance-tests/features/club_member_invitations.feature` now has no remaining `@todo-domain` or `@todo-ui` tags.
- `git status` shows the two intended modified files plus the pre-existing untracked `.fabro/tmp/` repair-baseline directory.