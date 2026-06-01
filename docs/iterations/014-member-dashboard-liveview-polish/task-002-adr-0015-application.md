# Task 002 ADR 0015 application notes

## ADR read

Read `docs/adr/0015-use-liveview-for-member-application-pages.md` on 2026-06-01. ADR 0015 is accepted and binding for this iteration.

## Decision applied to the member dashboard

The signed-in selected-club home at `GET /?club_id=<club_id>` is a member application surface, not a static marketing page. It depends on authenticated identity, selected club context, active membership authorization, dashboard data, message rows, receipt glances, and member-only navigation. Per ADR 0015, the dashboard should therefore be implemented as `MembaWeb.MemberDashboardLive` rather than continuing as a controller-rendered template.

The existing `GET /` controller boundary may remain only as the dispatcher/public rendering boundary required by the iteration plan:

- logged-out visitors with `club_id` continue to receive the public/marketing club experience;
- signed-in active members with `club_id` are dispatched to the LiveView-backed member dashboard at the same user-visible URL;
- signed-in non-members, inactive members, unknown clubs, and requests without selected club context preserve existing auth/not-found/home behaviour.

## Constraints for later implementation tasks

- Keep the user-visible address as `/?club_id=<club_id>`; do not introduce a separate dashboard URL for this slice.
- Name the member app LiveView with the project/ADR convention: `MembaWeb.MemberDashboardLive`.
- Keep member dashboard chrome inside the existing club-site shell (`<Layouts.club_site>`), not a standalone marketing layout.
- Move member-dashboard data shaping out of the controller path and into the LiveView/presentation-helper path planned for tasks 003-005.
- Preserve stable browser-facing selectors from the current club home unless they are deliberately updated with matching helper/test changes in the selector-preservation task.
- Keep static/legal/marketing pages controller-rendered where appropriate; ADR 0015 does not require converting logged-out marketing pages just because the signed-in dashboard becomes LiveView-backed.

## Test implications

Focused Phoenix/LiveView tests added in later tasks should prove the ADR application by asserting that signed-in active members reach the LiveView-backed dashboard at `GET /?club_id=<club_id>` while logged-out public club behaviour and forbidden member flows remain unchanged.
