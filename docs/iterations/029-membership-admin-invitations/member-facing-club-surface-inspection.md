# Member-facing club surface inspection

Selected task: `002 Inspect current member-facing club pages to find whether a members list already exists. If it exists, add the invite action there for Membership Admins. If it does not, add the smallest member-facing club members/admin page needed to host the invite action.`

## Finding

A member-facing members list already exists on the signed-in club dashboard:

- Controller handoff: `MembaWeb.PageController.render_member_dashboard/3`
- LiveView: `MembaWeb.MemberDashboardLive`
- Presentation loader: `MembaWeb.MemberDashboardPresentation`
- Template: `web/lib/memba_web/controllers/page_html/club.html.heex`
- Members section: `section#club-members`
- Members card/list affordance: `#active-members-card` with `data-testid="club-member-row"` rows

The dashboard is reachable for active members from both existing club entry modes:

- app host query route: `/?club_id=<club_id>`
- club subdomain host route: `/`

Private member routes already use the same host/query distinction for message composition, so the invitation entry point should follow that style.

## Surface decision

Use the existing `#club-members` section rather than adding a separate members/admin page in this slice. This keeps the iteration small and follows the plan's preference to reuse an existing members list when present.

This task adds the first invitation affordance there:

- DOM ID: `#member-invite-member-link`
- Copy: `Invite member`
- Query-host href shape: `/members/invitations/new?club_id=<club_id>`
- Club-subdomain href shape: `/members/invitations/new`

The target route/form is intentionally left for the next route/action task.

## Membership Admin visibility

The dashboard presentation now derives `current_member_can_manage_members?` from the existing Membership authorization read model:

- `Memba.Membership.Authorization.authorize_manage_members/2`
- permission: `Memba.Membership.Permissions.club_manage_members()`
- person ID: the signed-in active member row loaded for the selected club

The template shows the invite link only when that assign is true.

## Follow-on implications

- Task 003 can add the member-facing `/members/invitations/new` route/action matching the link introduced here.
- Task 004 should enforce `club.manage_members` at the route/action boundary, not just rely on this link visibility.
- Task 005 should add direct URL/crafted request rejection coverage for ordinary members once the route exists.

## ADR conformance notes

- ADR 0009: invite visibility reads from the existing Ecto projection-backed member-permission read model instead of inventing a parallel permission store.
- ADR 0013: the UI affordance was covered from user-visible LiveView behaviour with existing Phoenix LiveView test helpers.
- ADR 0015: the new member application affordance stays on the existing LiveView-backed club dashboard rather than adding a controller-rendered member app page.
- ADR 0022: this task introduces no new command/read-after-write flow; later invitation submission work should continue to use existing strong consistency/projection-barrier practices when it writes invitation state and then renders from projections.
