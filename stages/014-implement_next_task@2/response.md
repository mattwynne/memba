1. **Selected todo line**
   - Original first unchecked line:
     - `002 Inspect current member-facing club pages to find whether a members list already exists. If it exists, add the invite action there for Membership Admins. If it does not, add the smallest member-facing club members/admin page needed to host the invite action.`

2. **Changes made**
   - Added inspection note:
     - `docs/iterations/029-membership-admin-invitations/member-facing-page-inspection.md`
   - Documented that an existing member-facing members surface already exists:
     - `web/lib/memba_web/controllers/page_html/club.html.heex`
     - `section#club-members`
     - `#active-members-card`
     - `[data-testid="club-member-row"]`
   - Recorded the decision to use that existing dashboard members section for the Membership Admin invite action rather than creating a new members/admin page.
   - Documented recommended later implementation shape:
     - Add invite link in `section#club-members`.
     - Preserve existing selectors.
     - Use `club.manage_members` via Membership public permission API.
     - Use a member-facing LiveView route consistent with existing host/query club selection patterns.

3. **Focused validation**
   - Ran `git diff --check`
     - Passed with no whitespace errors.
   - Ran `git status --short`
     - Shows expected docs-only changes:
       - modified `todo.md`
       - new `member-facing-page-inspection.md`
   - Did **not** run `dev check` because this was docs/inspection-only, consistent with project guidance.

4. **Todo check-off made**
   - Split the original task so the executable UI work remains pending.
   - Checked off:
     - `- [x] 002 Inspect current member-facing club pages and decide whether to use an existing members list or add a new member-facing members/admin page.`

5. **Todo splits/additions/reordering**
   - Added pending task:
     - `- [ ] 005a Add the invitation action to the selected member-facing members surface for Membership Admins once it can target the route and permission-gated visibility.`
   - Reason: adding the actual invite action before tasks 003–005 would require either a missing route or premature permission-gated UI work. The split preserves the original plan requirement while keeping this task limited to inspection/placement.

6. **ADR conformance evidence**
   - ADR 0015: documented that the future member invitation page should be LiveView because it is an authenticated member app surface with form, validation, and permission-dependent behavior.
   - ADR 0007: documented that web code should use Membership public APIs and not query Membership projection tables directly.
   - Iteration 027 role-permission model: documented use of `club.manage_members` through `Memba.Membership.person_has_club_permission?/3`, not role names or Staff identity.