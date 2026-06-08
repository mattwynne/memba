### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - Working tree is clean.
  - Recent checkpoint `cc32f97 fabro(...): implement_next_task (succeeded)` is the just-completed implementation commit.
  - `git show cc32f97 -- docs/iterations/029-membership-admin-invitations/todo.md` shows exactly one ordinary task line changed:
    - `003 Add a member-facing route/action for inviting club members, scoped to the current club.`
    - from `- [ ]` to `- [x]`.
  - Parent todo showed tasks 001–002 already checked and task 003 as the first unchecked task.

- Implementation artifacts found:
  - Added member-facing LiveView route in `web/lib/memba_web/router.ex`:
    - `GET /members/invitations/new`
    - `MembaWeb.MemberInvitationLive.New`
    - through `[:browser, :club_member_required]`.
  - Added `web/lib/memba_web/live/member_invitation_live/new.ex` with club-scoped mount/render behaviour for query-host and club-subdomain contexts.
  - Updated `web/lib/memba_web/controllers/page_html.ex` invitation path helper to use verified `~p` routes.
  - Added route and LiveView tests:
    - `web/test/memba_web/router_test.exs`
    - `web/test/memba_web/live/member_invitation_live/new_test.exs`.

- Tests run/results found:
  - Validator reran `PATH="$PWD/bin:$PATH" dev check --quick`.
  - Result: `727 tests, 0 failures`.
  - Working tree remained clean after validation.
  - Implementation summary also reported full `dev check` passing with ExUnit and acceptance tests.

- ADR/plan conformance notes:
  - Scope matches task 003: a member-facing, club-scoped route/action entry point was added; manage-members authorization and direct ordinary-member rejection remain correctly unchecked as tasks 004–005.
  - No acceptance feature files were changed in the implementation checkpoint.
  - ADR 0015 respected: new member application surface is a LiveView.
  - ADR 0013 respected: user-visible routing/LiveView behaviour has tests; lower-level LiveView/router assertions are appropriate for route/session mechanics.
  - ADR 0009 respected: uses existing projection-backed membership/club reads rather than new state.
  - ADR 0022 not triggered by this task because no command/write/read-after-write flow was introduced.
  - Checkpoint is focused and independently useful.

{"context_updates":{"task_valid":true,"task_retry_available":false}}