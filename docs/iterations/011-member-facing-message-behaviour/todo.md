# Implementation TODO

- [x] 001 Inspect current authenticated club-site routes and the design references listed above.
- [ ] 002 Add member acceptance support:
- [ ] 003 Update member step definitions so:
- [ ] 004 Build/refine member club home at `GET /?club_id=<club_id>`:
- [ ] 005 Add member message detail at `GET /messages/:message_id?club_id=<club_id>`:
- [ ] 006 Add a presentation mapping for member receipt labels and Heroicons without changing internal projection values.
- [ ] 007 Keep staff/admin diagnostics unchanged on `/admin/messages/:message_id` and `/admin/deliveries`.
- [ ] 008 Add focused tests for member route authorization, message-club ownership checks, status label/icon mapping, and no operator-only fields on member pages.
- [ ] 009 Remove `@wip` from `member_message_deliverability.feature` when browser scenarios pass.
- [ ] 010 Run `dev check`.
