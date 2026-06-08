# Member-facing members surface inspection

Selected task: `002 Inspect current member-facing club pages to find whether a members list already exists. If it exists, add the invite action there for Membership Admins. If it does not, add the smallest member-facing club members/admin page needed to host the invite action.`

## Conclusion

An existing member-facing members list already exists on the signed-in member dashboard. No new standalone member-facing members/admin page is needed for this iteration.

The Membership Admin invitation entry point should be added to the existing dashboard `#club-members` section / `#active-members-card` in `web/lib/memba_web/controllers/page_html/club.html.heex`, gated by the signed-in member's `club.manage_members` permission for the selected club.

The actual invite action/link/form is intentionally left for the following implementation tasks because it depends on the member-facing invitation route/action and permission-aware assigns that are explicitly covered by tasks 003-005.

## Existing member-facing club routes

Current member-facing routing in `web/lib/memba_web/router.ex` has:

- `GET /` through `PageController.home/2`, which renders `MembaWeb.MemberDashboardLive` for a signed-in active member of the selected club.
- Member LiveViews under the `:club_member_required` pipeline:
  - `GET /messages/new` (`MembaWeb.MemberMessageLive.New`)
  - `GET /messages/:message_id` (`MembaWeb.MemberMessageLive.Show`)

There is no standalone member-facing `/members` or `/members/admin` route today.

## Existing members list

The signed-in member dashboard is mounted by `MembaWeb.PageController.render_member_dashboard/3` and rendered by `MembaWeb.MemberDashboardLive`.

`MembaWeb.MemberDashboardPresentation.load/3` already loads:

- `:selected_club`
- `:members`
- `:active_member_count`
- `:current_member`

from `Memba.Membership.list_active_members_of_club/1`, with selected-club and active-member authorization enforced before rendering.

The rendered HEEx template `web/lib/memba_web/controllers/page_html/club.html.heex` contains the existing member-facing members list:

- section id: `#club-members`
- card id: `#active-members-card`
- member rows: `[data-testid="club-member-row"]`
- empty/first-member state: `#active-members-empty-state`
- active-member avatar stack: `#active-members-avatar-stack`

This satisfies the plan's preferred UI entry condition: "Reuse an existing club members list if one exists."

## Placement recommendation for the invitation entry point

Add the Membership Admin invite entry point inside `#club-members`, near the "Current members" heading or inside `#active-members-card`, so the invitation action is colocated with the member list it affects.

Recommended stable selectors for later tests:

- link/action id: `#member-invite-member-link`
- host section: `#club-members`
- destination should be a member-facing, club-scoped route from task 003.

For club-host access, member routes already support host-selected club context via `MembaWeb.Plugs.ClubSiteMemberRoute`. For query-selected access, existing helper patterns in `MembaWeb.PageHTML` preserve the selected club with `?club_id=...`. The invite route should follow the same host/query convention as the existing member message routes so both `https://<club>.lvh.me/` and `/?club_id=<club_id>` journeys remain consistent.

## Permission data needed before rendering the action

Iteration 027 already provides the permission query:

- `Memba.Membership.person_has_club_permission?(club_id, person_id, Permissions.club_manage_members())`

The dashboard currently has `:current_member` with `id`, `membership_id`, `name`, `email`, and initials, but it does not yet expose a `:can_manage_members?` or similar assign. A later task should add a permission-aware assign using the current member's person ID and selected club ID, then render the invite entry point only when that assign is true.

## Why no code change is included in this slice

The selected todo line combines inspection/placement with adding the invite action. Adding the action safely requires:

1. a member-facing invitation route/action (task 003),
2. authorization using `club.manage_members` (task 004), and
3. ordinary-member non-visibility/direct-access rejection (task 005).

Adding only a visible link now would either point at a missing route or risk exposing a broken/unauthorized action. The todo list has therefore been split so this inspection and placement decision is durable while the implementation remains pending in the planned route/authorization slices.

## ADR conformance

- ADR 0001 keeps the core application in Phoenix; this inspection identifies the existing Phoenix member dashboard surface.
- ADR 0015 says member application pages should use LiveView by default; the existing member dashboard is already a LiveView-backed member app surface, so reusing it avoids creating a controller-rendered member admin page.
- ADR 0007 keeps Membership and Messaging separate; this placement decision uses Membership permission queries for membership-management UI and does not introduce Messaging-owned membership behaviour.
- ADR 0009 uses Ecto projections for read models; the dashboard already reads current membership state from Membership projections through public query APIs.
