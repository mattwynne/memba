### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - Live `git status --short` is clean.
  - Recent checkpoint `f77e24a fabro(...): implement_next_task (succeeded)` contains the just-completed task.
  - `git diff f77e24a^ f77e24a -- docs/iterations/029-membership-admin-invitations/todo.md` shows exactly one ordinary task changed:
    - `004 Authorize the route/action using the club.manage_members permission for the signed-in person in the current club.`
    - from `- [ ]` to `- [x]`.
  - Parent todo state had tasks 001–003 checked and 004 as the first unchecked task.

- Implementation artifacts found:
  - `web/lib/memba_web/live/member_invitation_live/new.ex`
    - Adds `Memba.Membership.Authorization`.
    - Calls `Authorization.authorize_manage_members(club_id, current_member.id)` while loading the invitation context.
    - Converts missing/unauthorized context to existing `MembaWeb.ForbiddenError` behavior.
  - `web/test/memba_web/live/member_invitation_live/new_test.exs`
    - Grants `club.manage_members` in successful invitation page tests.
    - Adds a direct routed GET rejection test for an active member without `club.manage_members`.
    - Adds a focused `grant_manage_members!/1` helper using the existing `MemberPermission` projection.

- Tests run/results found:
  - Validator reran `PATH="$PWD/bin:$PATH" dev check --quick`.
  - Result: passed, `728 tests, 0 failures`.
  - Working tree remained clean after validation.
  - Implementation summary also reported full `dev check` passing with acceptance tests.

- ADR/plan conformance notes:
  - Scope matches task 004: the member-facing invitation route/action is now permission-gated by `club.manage_members`.
  - The work is a small independent checkpoint and does not prematurely implement remaining invitation lifecycle tasks.
  - No acceptance feature files changed in this checkpoint.
  - ADR 0015 respected: member-facing surface remains a LiveView.
  - ADR 0013 respected: route/LiveView authorization behavior has web test coverage; lower-level helpers are appropriate for route/session/error mechanics here.
  - ADR 0009 respected: uses existing projection-backed permission read model.
  - ADR 0022 not triggered: no new command/write/read-after-write flow was added.

{"context_updates":{"task_valid":true,"task_retry_available":false}}