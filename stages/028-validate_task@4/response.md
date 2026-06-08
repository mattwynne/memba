### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found.
  - Working tree is clean and live `git diff` is empty, so the implementation is in a recent Fabro checkpoint.
  - Recent checkpoint `8bbd316 fabro(...): implement_next_task (succeeded)` changed exactly one ordinary todo line:
    - `003 Add a member-facing route/action for inviting club members, scoped to the current club.`
    - from `- [ ]` to `- [x]`.
  - Its parent todo showed `003` was the first unchecked task at implementor start.

- Implementation artifacts found.
  - `web/lib/memba_web/router.ex`
    - Adds `GET /members/invitations/new` inside the existing `:browser, :club_member_required` pipeline and `:club_member` LiveView session.
  - `web/lib/memba_web/live/club_member_invitations_live/new.ex`
    - Adds `MembaWeb.ClubMemberInvitationsLive.New`.
    - Resolves club scope from `club_id` query params or club-site host session context.
    - Confirms the signed-in identity is an active member of the selected club before rendering.
    - Renders a club-scoped invitation entry shell without prematurely implementing pending authorization/form/submission tasks.
  - `web/test/memba_web/router_test.exs`
    - Adds route coverage for the new member invitation route and required club-member pipeline.
  - `web/test/memba_web/live/club_member_invitations_live/new_test.exs`
    - Adds LiveView coverage for query-selected club scope, host-selected club scope, and signed-out redirect/return path.

- Tests run/results found.
  - Live validation run:
    - `devenv shell -- bin/mix test test/memba_web/router_test.exs test/memba_web/live/club_member_invitations_live/new_test.exs`
    - Passed: `16 tests, 0 failures`.
  - `git diff --check 8bbd316^ 8bbd316` passed.
  - Implementor summary also reported formatting and `dev check` passed.
  - No `*.feature` files were changed in the checkpoint.

- ADR/plan conformance notes.
  - Stays within plan task 003: adds the member-facing club-scoped route/action surface only.
  - Does not delete, weaken, or silently defer plan-required work; authorization, visibility, form, invitation lifecycle reuse, and acceptance tag work remain pending in `todo.md`.
  - Respects ADR 0001 by staying in Phoenix.
  - Respects ADR 0015 by using LiveView for a member-facing app page.
  - Uses existing Membership read/query/projection state for club/member scoping, consistent with ADR 0007/0009 boundaries.
  - The checkpoint is small and independently useful.

{"context_updates":{"task_valid":true,"task_retry_available":false}}