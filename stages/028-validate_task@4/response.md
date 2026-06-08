### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found.
  - Working tree is clean.
  - Recent checkpoint `3b20fd7 fabro(...): implement_next_task (succeeded)` changed exactly one ordinary todo line:
    - `004 Authorize the route/action using the club.manage_members permission for the signed-in person in the current club.`
    - from `- [ ]` to `- [x]`.
  - `3b20fd7^:docs/iterations/029-membership-admin-invitations/todo.md` shows task `004` was the first unchecked task before the implementation checkpoint.

- Implementation artifacts found.
  - `web/lib/memba_web/live/member_invitation_live/new.ex` now:
    - resolves the signed-in identity to a projected person;
    - verifies the selected club from the signed-in identity’s club context;
    - authorizes using `Memba.Membership.person_has_club_permission?/3`;
    - requires `Memba.Membership.Permissions.club_manage_members()`;
    - raises `MembaWeb.ForbiddenError` when unauthorized.
  - `web/test/memba_web/live/member_invitation_live/new_test.exs` now creates Membership Admin fixtures with projected `MemberPermission` records and covers:
    - successful routed access for members with `club.manage_members`;
    - forbidden access for ordinary active members;
    - forbidden access when the permission belongs to a different club.

- Tests run/results found.
  - Live validation reran focused tests:
    - `PATH="$PWD/bin:$PATH" devenv shell -- bin/mix test test/memba_web/live/member_invitation_live/new_test.exs test/memba_web/router_test.exs`
    - Result: `18 tests, 0 failures`.
  - `git show --check 3b20fd7` passed.
  - Implementation summary reports `dev check` passed, including acceptance tests.
  - Working tree remained clean after validation.

- ADR/plan conformance notes.
  - Scope matches task `004`: route/action authorization by `club.manage_members`; visibility, form submission, command reuse, and acceptance tag work remain pending.
  - The implementation uses the Membership public API for authorization rather than exposing projection-query details in the LiveView.
  - The member-facing surface remains a LiveView.
  - No acceptance feature files were changed in the implementation checkpoint.
  - No plan-required todo work was deleted, weakened, or silently deferred.

{"context_updates":{"task_valid":true,"task_retry_available":false}}