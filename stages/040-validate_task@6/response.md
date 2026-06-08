### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found.
  - Live working tree is clean; `git status --short` and `git diff` are empty.
  - `/tmp/fabro-pre-validate-snapshot.md` shows the implementation checkpoint as `47cfd90`.
  - Recent history confirms `47cfd90 fabro(...): implement_next_task (succeeded)` followed by `2268b17 ... pre_validate_snapshot`.
  - `git show 47cfd90` changes exactly one ordinary todo line:
    - `005 Ensure ordinary members do not see the invitation action and cannot use it by direct URL or crafted request.`
    - from `- [ ]` to `- [x]`.
  - The predecessor todo at `e691f07` shows task `005` was the first unchecked task when implementation started.

- Implementation artifacts found.
  - `web/test/memba_web/live/member_dashboard_live_test.exs`
    - Adds coverage that an ordinary member does not see invitation affordances in `#club-members`.
  - `web/test/memba_web/live/club_member_invitations_live/new_test.exs`
    - Adds coverage that an ordinary member on a club subdomain is rejected with `MembaWeb.ForbiddenError` / `403` when directly requesting `/members/invitations/new`.
  - Existing implementation in `web/lib/memba_web/live/club_member_invitations_live/new.ex` enforces `club.manage_members` through `Membership.person_has_club_permission?/3` and raises `MembaWeb.ForbiddenError` otherwise.
  - No acceptance feature files were changed in the implementation checkpoint.

- Tests run/results found.
  - I ran the focused tests live:
    - `devenv shell -- bin/mix test test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/club_member_invitations_live/new_test.exs`
    - Result: `18 tests, 0 failures`.
  - Implementor also reported `dev check --quick` passing with `729 tests, 0 failures`.

- ADR/plan conformance notes.
  - Work stays within plan task `005` and preserves remaining scope; no plan-required work was removed, weakened, or silently deferred.
  - The checkpoint is small and independently useful: it adds authorization/visibility regression coverage for ordinary members.
  - ADR 0001 respected: remains in Phoenix/Phoenix LiveView.
  - ADR 0007 respected: authorization uses Membership context boundaries.
  - ADR 0009 respected: permission state is read through projected/read-model-backed Membership APIs.
  - ADR 0015 respected: member-facing behaviour is covered through LiveView tests.

{"context_updates":{"task_valid":true,"task_retry_available":false}}