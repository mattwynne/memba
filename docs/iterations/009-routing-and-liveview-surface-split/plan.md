# Routing and LiveView surface split

Date: 2026-05-31
Status: validated

## Goal

Split the current unauthenticated browser harness into clear public, staff-admin, and future club-site surfaces, without adding member auth, custom-domain routing, or new business behaviour yet.

After this iteration, the existing operational tools live under `/admin/*`, the public site remains Memba-branded, and the codebase has explicit seams for the future white-label club member site.

## Background / Context

The designer handoff in `design_handoff_navigation/README.md` and `blueprint/index.html` defines three audiences:

1. Visitors use the Memba-branded public marketing site.
2. Memba staff use a Memba-branded internal back-end to create clubs, add members, and inspect delivery health.
3. Club members use a white-label site on the club's own domain, with only a quiet “Powered by Memba” credit.

The app currently exposes the browser acceptance harness at unauthenticated routes:

- `/clubs`
- `/clubs/:club_id`
- `/messages/:message_id`
- `/deliveries`

Those routes mix staff operations, member-facing reading, message composition, and delivery diagnostics. This iteration re-homes the existing staff/operator behaviour first and prepares the module/layout structure for later member-facing work.

## Scope

### In scope

- Move existing staff/operator LiveViews to `/admin/*` route paths:
  - `/admin/clubs`
  - `/admin/clubs/:club_id`
  - `/admin/messages/:message_id`
  - `/admin/deliveries`
- Rename or wrap LiveView modules so their names reflect the staff surface, for example:
  - `MembaWeb.Admin.ClubsLive.Index`
  - `MembaWeb.Admin.ClubsLive.Show`
  - `MembaWeb.Admin.MessagesLive.Show`
  - `MembaWeb.Admin.DeliveriesLive.Index`
- Remove the old harness routes immediately. They should return the normal 404; no redirects are needed because nobody is using the product yet.
- Keep public pages at `/`, `/about`, `/terms`, and `/privacy`.
- Introduce layout/component seams for the three surfaces:
  - public Memba marketing layout/chrome,
  - staff admin layout/chrome,
  - club-site white-label layout/chrome for future use.
- Introduce a club-site namespace and skeleton modules only where useful to make the next slice obvious. Do not expose production member routes unless they can avoid fake club resolution.
- Preserve `POST /webhooks/postmark` unchanged.
- Update tests and navigation links to the new `/admin/*` paths.
- Keep `dev check` green.

### Out of scope

- Magic-link member authentication.
- Staff authentication or authorization beyond the route split.
- Request-an-account lead capture.
- Real custom-domain club resolution.
- Temporary production-like club resolution by query string, path prefix, or “first club”.
- Club brand persistence, logo upload, or self-serve brand controls.
- Club-branded emails.
- Directory and sent-message member views as working product pages.
- High-fidelity implementation of the marketing prototype.
- Billing, subscriptions, renewals, dues, events, or public club page editing.

## Acceptance Criteria

- Visiting `/` still shows the Memba marketing homepage.
- Visiting `/about`, `/terms`, and `/privacy` still returns successful public pages.
- Visiting `/admin/clubs` shows the club list and create-club form.
- Creating a club from `/admin/clubs` still dispatches the existing `Membership.create_club/2` behaviour.
- Visiting `/admin/clubs/:club_id` shows the selected club, its members, and the existing staff tools for member/message management.
- Visiting `/admin/messages/:message_id` shows delivery diagnostics for that message.
- Visiting `/admin/deliveries` shows the operator delivery overview.
- Visiting old harness URLs `/clubs`, `/clubs/:club_id`, `/messages/:message_id`, and `/deliveries` returns the normal 404 page (no redirects).
- Public homepage navigation and calls to action no longer point at `/clubs`; staff/admin entry points use `/admin/clubs` where needed.
- `POST /webhooks/postmark` remains routed exactly as before.
- The codebase has named layout/module seams for public, admin, and future club-site surfaces.
- No temporary club resolver is introduced for member routes.

## Open Business Decisions

None known for this technical slice.

Business decisions explicitly deferred:

- How staff users authenticate.
- How club domains map to clubs.
- How club-branded sending domains are verified and used.
- How account requests are reviewed and converted into clubs.

## Implementation Plan

1. Update `web/lib/memba_web/router.ex`:
   - Keep public controller routes under `/`.
   - Add an `/admin` scope for staff LiveViews using a `:staff_browser` pipeline that currently mirrors `:browser`.
   - Remove the old public harness LiveView routes.
   - Leave `/webhooks/postmark` unchanged.
2. Move or rename existing LiveView modules into an admin namespace:
   - `ClubsLive.Index` → `Admin.ClubsLive.Index`.
   - `ClubsLive.Show` → `Admin.ClubsLive.Show`.
   - `MessagesLive.Show` → `Admin.MessagesLive.Show`.
   - `DeliveriesLive.Index` → `Admin.DeliveriesLive.Index`.
3. Update all internal verified routes and links:
   - Club list/detail links should use `/admin/clubs` and `/admin/clubs/:club_id`.
   - Message diagnostic links should use `/admin/messages/:message_id`.
   - Delivery overview links should use `/admin/deliveries`.
4. Add or adjust layout functions in `MembaWeb.Layouts`:
   - Keep a Memba-branded public/app layout for marketing/legal pages.
   - Add an admin layout for staff pages, with utilitarian Memba chrome.
   - Add a club-site layout seam for future white-label pages using CSS custom properties with a neutral slate default, but do not wire fake club routing into production routes.
5. Update the homepage links and labels so the primary operational link points to `/admin/clubs` if retained, or is presented as an internal/admin link rather than a public user journey.
6. Update controller and LiveView tests to assert the new paths.
7. Add route tests asserting old harness paths return 404 (not redirects).
8. Run `bin/dev check` and fix any route/module/test failures.

## Technical Decisions

- Physically move LiveView files into `web/lib/memba_web/live/admin/...` to match module names.
- Introduce a `:staff_browser` pipeline now for future staff auth; it should currently delegate to `:browser`-equivalent plugs as an obvious auth insertion point.
- Implement a real `Layouts.club_site` layout seam with default theme assigns (rather than a placeholder module/component).

## New Capability

The application will have a clean routing and module structure that reflects the product's three surfaces. Staff tools will no longer masquerade as public pages, and future club-member work can start from a named white-label surface instead of extracting behaviour from the harness.

## Validation Plan

- Run `bin/dev check`.
- Automated route/controller/LiveView tests should cover:
  - public pages still work,
  - admin routes render the moved pages,
  - old harness routes return 404 (no redirects),
  - Postmark webhook route remains available.
- Manual smoke test:
  1. Open `/` and confirm public homepage renders.
  2. Open `/admin/clubs`, create a club, and open its detail page.
  3. Add or view members on `/admin/clubs/:club_id`.
  4. Send or inspect a message if test data is available.
  5. Open `/admin/messages/:message_id` and confirm diagnostics are staff-facing.
  6. Open `/admin/deliveries` and confirm the operator overview renders.
  7. Confirm `/clubs` returns the normal 404 page (and does not render the club list).

## Risks / Follow-ups

- This does not provide real security for `/admin/*`; staff auth must be a later slice before real users or sensitive data are present.
- The member-facing white-label routes are intentionally not exposed yet. The next member-facing slice should start with real club resolution and/or magic-link auth rather than temporary URL hacks.
- Moving modules can break tests that refer to route paths, DOM IDs, or module names; keep DOM IDs stable where acceptance tests depend on them.
- The existing `ClubsLive.Show` still mixes add-member, send-message, and message list responsibilities. Further extraction should happen when member-facing noticeboard/compose pages are implemented.
