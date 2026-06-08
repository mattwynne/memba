# Member-facing club page inspection

Original selected task: `002 Inspect current member-facing club pages to find whether a members list already exists. If it exists, add the invite action there for Membership Admins. If it does not, add the smallest member-facing club members/admin page needed to host the invite action.`

Execution split:

- Completed as task `002`: inspect current member-facing club pages and decide whether to use an existing members list or add a new member-facing members/admin page.
- Preserved as pending task `005a`: add the invitation action to the selected member-facing members surface for Membership Admins once it can target the route and permission-gated visibility.

## Decision

An existing member-facing members list surface already exists: the signed-in club dashboard renders a `Current members` section in `web/lib/memba_web/controllers/page_html/club.html.heex`.

Because that surface exists, iteration 029 should add the Membership Admin invite entry point there instead of introducing a separate members/admin page in this slice.

The actual invite link/form is preserved as a pending todo after the route and authorization tasks, because adding a link before the member-facing invitation route exists would either point at a missing route or bypass the planned `club.manage_members` visibility rule.

## Current member-facing club surfaces

Member-facing club app routes are currently split between:

- `GET /?club_id=<club_id>` on the main host, rendered by `MembaWeb.PageController.home/2`.
- `GET /` on a club subdomain, resolved by `MembaWeb.ClubSite.slug_from_host/1`.
- Private member routes under the `:club_member_required` pipeline:
  - `GET /messages/new` -> `MembaWeb.MemberMessageLive.New`
  - `GET /messages/:message_id` -> `MembaWeb.MemberMessageLive.Show`

`MembaWeb.PageController` uses `Phoenix.LiveView.Controller.live_render/3` to render `MembaWeb.MemberDashboardLive` for signed-in active members. Logged-out visitors and signed-in non-members still see the public club page when it is visible.

For private routes, `MembaWeb.Plugs.ClubSiteMemberRoute` resolves the club from the subdomain host and injects `club_id` into route params. On the main host, private member routes use the `club_id` query parameter. This gives member-facing links two existing path shapes:

- Query-selected club: `/messages/new?club_id=<club_id>`
- Host-selected club: `/messages/new`

The Membership Admin invite route/link should follow the same pattern so query-based tests and club-subdomain browser journeys remain consistent.

## Existing members list surface

`web/lib/memba_web/controllers/page_html/club.html.heex` renders:

- Root dashboard container: `#member-club-home`
- Members section: `section#club-members`
- Members card: `#active-members-card`
- First-member empty-ish state: `#active-members-empty-state`
- Active-member avatar stack: `#active-members-avatar-stack`
- Per-member acceptance/test rows: `[data-testid="club-member-row"]`

`MembaWeb.MemberDashboardPresentation.load/3` already loads active club members through `Membership.list_active_members_of_club/1`, presents initials, exposes:

- `:members`
- `:active_member_count`
- `:current_member`
- `:selected_club`

Existing tests assert this surface in:

- `web/test/memba_web/live/member_dashboard_live_test.exs`
- `web/test/memba_web/controllers/page_controller_test.exs`
- `web/test/memba_web/member_dashboard_presentation_test.exs`

This means the plan's preferred UI entry already exists. A new standalone member-management page is not needed for iteration 029's first invitation action.

## Recommended placement for the invite action

Add the Membership Admin-only action to `section#club-members`, ideally in the section header next to `Current members`.

Suggested selector and copy for later web tests:

- Link id: `member-invite-member-link`
- Copy: `Invite member`
- Link target:
  - Host-selected club: `/members/invitations/new`
  - Query-selected club: `/members/invitations/new?club_id=<club_id>`

That keeps the invite affordance close to the current member list, preserves the existing message CTA as the primary dashboard action, and avoids creating pending-invitation management UI that is out of scope for this iteration.

## Authorization seams for the later UI task

The dashboard currently knows the current active member row but does not expose permission state to the template. The later visibility task should add a small assign such as `:can_manage_members?` to the dashboard presentation data after resolving `current_member`.

Use the Membership public permission API rather than reading projection tables directly:

- Permission identifier: `Memba.Membership.Permissions.club_manage_members/0`
- Permission query: `Memba.Membership.person_has_club_permission?/3`

This keeps the UI aligned with the iteration 027 role-permission model and avoids checking hard-coded role names like `Membership Administrator`.

## Route/page implications for following tasks

The next member-facing invitation page should be a LiveView, consistent with ADR 0015's default for member application pages.

Recommended shape:

- Add a private member route under the existing `scope "/", MembaWeb` with `pipe_through [:browser, :club_member_required]`.
- Use the existing `:club_member` `live_session`.
- Add a LiveView module such as `MembaWeb.MemberInvitationLive.New` or `MembaWeb.MemberClubMemberInvitationsLive.New`.
- Keep the form email-only.
- Load the current club through the same host/query club-selection semantics used by message compose.
- Authorize in the LiveView/application service with `club.manage_members`; ordinary active members must be rejected even though they pass `:club_member_required`.

The existing Staff route remains separate:

- `/admin/clubs/:club_id/invitations/new`

Do not reuse the Staff `/admin` route for club Membership Admins.

## Acceptance-selector impact

Because the existing dashboard member list has browser acceptance selectors, add new selectors without renaming or removing existing ones:

- Preserve `#club-members`.
- Preserve `#active-members-card`.
- Preserve `[data-testid="club-member-row"]`.
- Add `#member-invite-member-link` only when the signed-in active member has `club.manage_members`.

This supports the iteration 029 acceptance criteria:

- Membership Admins can reach the invitation action from the members list.
- Ordinary members do not see the invitation action.

## ADR conformance

- ADR 0015: the future member invitation page should be a LiveView because it is a member application page with authenticated club context, permission-dependent UI, a form, validation, and error states.
- ADR 0007: invitation lifecycle and authorization queries should stay in the Membership bounded context. The web layer should call Membership public APIs and must not query Membership projection tables directly.
- Iteration 027 role-permission model: use the `club.manage_members` permission through a public Membership query; do not authorize by role name, Staff identity, or implicit club administration.
