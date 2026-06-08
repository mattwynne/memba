### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found:
  - Live working tree is clean.
  - Recent checkpoint `f28f537 fabro(...): implement_next_task (succeeded)` contains the just-completed task evidence.
  - Its `todo.md` diff split the first unchecked task 002 into:
    - checked: `002a Inspect current member-facing club pages and decide the invitation host surface.`
    - pending: `002b Add the Membership Admin invite action to the existing member dashboard #club-members section once the member-facing invitation route/action and permission-aware assigns are in place.`
  - This is a clear plan-preserving first slice: inspection/placement completed, action implementation preserved for the route/authorization/non-visibility tasks.

- Implementation artifacts found:
  - Added `docs/iterations/029-membership-admin-invitations/member-facing-members-surface-inspection.md`.
  - The document records concrete findings:
    - existing member-facing members list exists on the member dashboard;
    - host surface is `#club-members` / `#active-members-card`;
    - no new standalone members/admin page is needed;
    - invite action should be gated by `club.manage_members`;
    - implementation is intentionally deferred until route/action and permission-aware assigns exist.
  - Corroborated referenced code exists, including:
    - `web/lib/memba_web/controllers/page_html/club.html.heex` with `#club-members`, `#active-members-card`, and member row selectors;
    - `MembaWeb.MemberDashboardLive`;
    - `MembaWeb.MemberDashboardPresentation`;
    - `Membership.list_active_members_of_club/1`;
    - `Membership.person_has_club_permission?/3`;
    - `Permissions.club_manage_members/0`.

- Tests run/results found:
  - No code/config/app-behaviour changed.
  - `git diff --check f28f537^..f28f537` passes.
  - Skipping `dev check` is justified for this docs/planning-only inspection slice under the project workflow.

- ADR/plan conformance notes:
  - Work stays within implementation task 002 and preserves the approved scope.
  - The split does not delete or weaken required work; the invitation action remains explicitly pending as 002b and is aligned with tasks 003–005.
  - No acceptance feature files were changed.
  - ADR constraints are respected:
    - ADR 0001: keeps Phoenix as the application surface.
    - ADR 0015: reuses the existing LiveView-backed member dashboard rather than introducing an unnecessary controller page.
    - ADR 0007: keeps membership-management concerns in Membership.
    - ADR 0009: continues using projected read models through public query APIs.
  - The checkpoint is small and independently useful.

{"context_updates":{"task_valid":true,"task_retry_available":false}}