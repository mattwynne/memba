# Implementation TODO

- [ ] 001 Inspect the current homepage template (`web/lib/memba_web/controllers/page_html/home.html.heex`) and the staff-access acceptance support (`acceptance-tests/features/support/homepage.js`).
- [ ] 002 Update `assertHomepageStaffAccess` to assert the staff bar (`a#staff-console-link` visible and linking to `/admin/clubs`, plus the visible "Memba staff" tag); confirm both `homepage.feature` staff scenarios fail against the current button.
- [ ] 003 Add the staff bar markup to the signed-in branch of the homepage template, gated on `@current_identity_staff?`, above `<header>`.
- [ ] 004 Remove the existing "Memba staff" nav button block (`#admin-home-link`) from the signed-in nav.
- [ ] 005 Run the homepage Cucumber scenarios and confirm they pass.
- [ ] 006 Run `dev check` and fix any issues.
- [ ] 007 Visual check against the design's staff mode (`wireframes/home.html`), including a narrow-screen pass for overflow.
