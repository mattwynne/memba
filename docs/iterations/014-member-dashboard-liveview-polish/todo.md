# Implementation TODO

- [x] 001 Inspect current `PageController.home/2`, `club.html.heex`, `UserAuth` club-member plugs, route tests, and browser helpers that rely on club-home selectors.
- [x] 002 Read ADR 0015 (`docs/adr/0015-use-liveview-for-member-application-pages.md`) and apply it to the member dashboard.
- [x] 003 Introduce `MembaWeb.MemberDashboardLive`, rendered for signed-in selected-club home while preserving public/logged-out handling for `/?club_id=`. Keep the existing `GET /` controller route as a small dispatcher/public page: logged-out visitors continue through the public/marketing rendering, while signed-in active club members with `club_id` get the LiveView-backed dashboard for the same URL. Do not add a separate user-visible dashboard URL in this slice.
- [ ] 004 Move selected-club dashboard data loading into the LiveView mount path plus a small query/presentation helper, `MembaWeb.MemberDashboardPresentation`, so the LiveView stays readable and the row-shaping logic is unit-testable:
- [ ] 005 Build message-row receipt glance data in `MembaWeb.MemberDashboardPresentation` using existing member receipt projections and `MembaWeb.MemberReceiptPresentation` where useful:
- [ ] 006 Render the dashboard toward `dashboard.jsx`:
- [ ] 007 Design and render empty states deliberately:
- [ ] 008 Preserve or deliberately update stable selectors used by browser acceptance:
- [ ] 009 Ensure the club home has no inline compose form; remove any remaining inline compose markup/handlers so compose is only reached through the CTA link to `/messages/new?club_id=<club_id>`.
- [ ] 010 Add focused LiveView/Phoenix tests for:
- [ ] 011 Run existing browser Cucumber for member-message deliverability and `dev check`.
