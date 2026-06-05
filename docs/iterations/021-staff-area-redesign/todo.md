# Implementation TODO

- [x] 001 Inspect the mockup HTML files and extract reusable layout ideas: staff operations shell, page header, navigation grouping, table density, status chips, action placement, and card/table treatment.
- [x] 002 Inspect current admin routes, LiveViews, layouts, tests, and acceptance helpers.
- [x] 003a Update `Layouts.admin` to the redesigned staff operations shell with the iteration-021 nav entries: Clubs, People, Messages, Deliveries.
- [x] 004 Add routes and LiveViews for read-only `/admin/people` and `/admin/messages` under the existing staff live session.
- [x] 004a Route-verify the People and Messages staff nav links after `/admin/people` and `/admin/messages` exist so the original task-003 working-link requirement is fully satisfied.
- [ ] 005 Add context/read-model queries as needed:
- [ ] 006 Keep the new index queries simple and deterministic; avoid implementing filters, pagination, bulk actions, or new statuses in this slice.
- [ ] 007 Restyle `/admin/clubs` to match the new staff operations direction while preserving club creation behaviour.
- [ ] 008 Restyle `/admin/clubs/:club_id` around club facts, people records, and memberships.
- [ ] 009 Remove the staff send-message form, its form assign/event handling, and any no-longer-needed member sender options from club detail.
- [ ] 010 Remove the embedded club messages list from club detail and replace it with a clear link/copy toward `/admin/messages` or future club-filtered messages.
- [ ] 011 Restyle person new/edit pages enough that they feel part of the redesigned staff area; preserve existing behaviour.
- [ ] 012 Restyle `/admin/deliveries` consistently without changing delivery semantics.
- [ ] 013 Restyle `/admin/messages/:message_id` consistently without changing diagnostics semantics.
- [ ] 014 Update or add LiveView tests for:
- [ ] 015 Update acceptance step support and remove the feature-level `@wip` tag from `memba_staff_operations.feature` once its scenarios pass.
- [ ] 016 Run targeted tests for admin LiveViews and acceptance configuration.
- [ ] 017 Run `dev check`.
