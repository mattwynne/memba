1. **Selected todo line**
   - Original first unchecked task:
     - `002 Inspect current member-facing club pages to find whether a members list already exists. If it exists, add the invite action there for Membership Admins. If it does not, add the smallest member-facing club members/admin page needed to host the invite action.`

2. **Changes made for this task**
   - Added durable inspection/placement notes:
     - `docs/iterations/029-membership-admin-invitations/member-facing-members-surface-inspection.md`
   - Findings documented:
     - An existing member-facing members list already exists on the signed-in member dashboard.
     - The host surface is `#club-members` / `#active-members-card` in `web/lib/memba_web/controllers/page_html/club.html.heex`.
     - No new standalone member-facing members/admin page is needed.
     - The later invite entry point should be gated by `club.manage_members`.
     - The dashboard currently lacks a permission-aware assign such as `:can_manage_members?`, so the actual link/action is best implemented with the later route/authorization tasks.
   - Updated `todo.md` by splitting task 002 into:
     - completed inspection/placement slice;
     - pending invite-action implementation slice.

3. **Focused validation**
   - Ran:
     - `git diff --check`
       - Passed with no whitespace errors.
     - `git status --short`
       - Confirmed only selected-task docs/todo changes:
         - `M docs/iterations/029-membership-admin-invitations/todo.md`
         - `?? docs/iterations/029-membership-admin-invitations/member-facing-members-surface-inspection.md`
   - Did not run `dev check` because this slice is docs/planning-only and does not change code, config, routes, UI, app behaviour, tests, or executable examples.

4. **Exact todo check-off made**
   - Replaced the original unchecked task 002 with:
     - `- [x] 002a Inspect current member-facing club pages and decide the invitation host surface.`
   - Added pending follow-up:
     - `- [ ] 002b Add the Membership Admin invite action to the existing member dashboard \`#club-members\` section once the member-facing invitation route/action and permission-aware assigns are in place.`
   - No other ordinary todo line was checked off.

5. **Todo splits/additions/reordering**
   - Split task 002 because its wording combined inspection/placement with adding the invite action, while the actual action depends on later explicit tasks:
     - task 003: member-facing route/action;
     - task 004: `club.manage_members` authorization;
     - task 005: ordinary-member non-visibility/direct-action rejection.
   - This preserves the approved plan without adding a broken link to a missing route or exposing unauthorised UI.

6. **ADR conformance evidence**
   - Reviewed relevant accepted ADRs:
     - ADR 0001: Phoenix remains the core application stack.
     - ADR 0015: member application pages should use LiveView by default.
     - ADR 0007: Membership and Messaging contexts remain separate.
     - ADR 0009: read models use Commanded Ecto projections.
   - The inspection decision conforms by reusing the existing LiveView-backed member dashboard and Membership projection/query APIs rather than introducing a separate controller-rendered admin surface or cross-context membership behaviour.