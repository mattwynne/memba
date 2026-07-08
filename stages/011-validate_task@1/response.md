### Decision
**RETRY**

### Evidence
- Completed todo/check-off evidence found:
  - Recent implementation checkpoint `a678eca` changed exactly one ordinary todo line:
    - `001 Inspect the existing role projection schemas and queries (...)` from `- [ ]` to `- [x]`.
  - This was the first unchecked task in `docs/iterations/049-member-role-badges/todo.md`.
- Implementation artifacts found:
  - Live working tree is clean.
  - `git show a678eca` shows the implementation checkpoint changed only `docs/iterations/049-member-role-badges/todo.md`.
  - No code/config/test/documentation artifact was added or changed to preserve the inspection findings.
  - Existing inspected files do corroborate the summary’s facts:
    - `RoleAssignment` has `club_id`, `membership_id`, `person_id`, `role_id`, `active`.
    - `Role` has `club_id`, `role_key`, `name`.
    - `Role` projector activates assignments on `MemberRoleAssigned`, deactivates on `MemberRoleRemoved`, and deactivates all membership assignments on `MemberRemoved`.
    - `Membership.list_active_members_of_club/1` currently returns active members without roles.
- Tests run/results found:
  - The implementation summary reports focused tests passed: `22 tests, 0 failures`.
  - No repository artifact records the inspection or test evidence beyond the summary.
- ADR/plan conformance notes:
  - The checked task is within the approved plan.
  - No acceptance feature files were edited.
  - Relevant ADRs 0002, 0007, 0009, 0021, and 0022 were respected by not changing architecture.
  - However, the validation contract requires concrete code/config/test/documentation evidence as appropriate, and says a todo-only change is invalid.

### Retry brief
Rejecting because live repository evidence shows the implementation checkpoint `a678eca` modified only `todo.md`. For this inspection task, the next clean attempt should add a small durable inspection note under `docs/iterations/049-member-role-badges/` capturing the confirmed schemas, active flags, projector behavior, current query shape, ADR notes, and focused test command/result, then check off task 001.

{"context_updates":{"task_valid":false,"task_retry_available":true}}