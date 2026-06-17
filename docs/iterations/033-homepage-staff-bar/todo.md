# Implementation TODO

- [x] 001 Inspect the current homepage template (`web/lib/memba_web/controllers/page_html/home.html.heex`) and the staff-access acceptance support (`acceptance-tests/features/support/homepage.js`).
- [x] 002 Update `assertHomepageStaffAccess` to assert the staff bar (`a#staff-console-link` visible and linking to `/admin/clubs`, plus the visible "Memba staff" tag). Note: the planned red-run check was skipped during local implementation; existing support still asserted `a#admin-home-link` before the implementation change.
- [x] 003 Add the staff bar markup to the signed-in branch of the homepage template, gated on `@current_identity_staff?`, above `<header>`.
- [x] 004 Remove the existing "Memba staff" nav button block (`#admin-home-link`) from the signed-in nav.
- [x] 005 Run the homepage Cucumber scenarios and confirm they pass.
- [x] 006 Run `dev check` and fix any issues. Fixed the dev-seed/test email delivery configuration leak and event-sourced reset cache issue uncovered by the gate, then confirmed `./bin/dev check --quick` and full `./bin/dev check` pass.
- [x] 007 Visual check against the design's staff mode (`wireframes/home.html`), including a narrow-screen pass for overflow. Verified the signed-in staff homepage at 390×844: staff bar and console link remain visible and the page fits the viewport.
