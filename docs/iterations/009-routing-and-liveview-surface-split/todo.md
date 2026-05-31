# Implementation TODO

- [x] 001 Update `web/lib/memba_web/router.ex`:
- [x] 002 Move or rename existing LiveView modules into an admin namespace:
- [x] 003 Update all internal verified routes and links:
- [ ] 004 Add or adjust layout functions in `MembaWeb.Layouts`:
- [ ] 005 Update the homepage links and labels so the primary operational link points to `/admin/clubs` if retained, or is presented as an internal/admin link rather than a public user journey.
- [ ] 006 Update controller and LiveView tests to assert the new paths.
- [ ] 007 Add route tests asserting old harness paths return 404 (not redirects).
- [ ] 008 Run `bin/dev check` and fix any route/module/test failures.
