# Implementation TODO

- [x] 001 Confirm production DNS prerequisite outside Fabro: `*.clubs.memba.io` points at the production Memba app before delivery starts.
- [x] 002 Inspect current Membership club command/event/aggregate/projector/projection code, public club route code, admin/staff route code, and all club creation call sites.
- [x] 003 Add `slug` to `CreateClub`, `ClubCreated`, `Memba.Membership.Club`, and `Memba.Membership.Projections.Club`.
- [x] 004 Implement slug generation and validation in a small Membership slug module or equivalent domain helper:
- [x] 005 Update `Membership.create_club/2` and relevant forms to use the generated default slug while allowing staff override.
- [x] 006 Add a migration to add `slug` to `membership_clubs`, backfill existing rows deterministically, set non-null, and create a unique index.
- [x] 007 Update the club projector to write `slug` from `ClubCreated` events.
- [x] 008 Do not support replay of old slug-less `ClubCreated` events. There is no live data yet; development/test event stores may be reset or backfilled as needed.
- [ ] 009 Add `Membership.get_club_by_slug/1`, using normalized lookup input only where safe and returning `nil` for invalid/unknown values.
- [ ] 010 Add a minimal staff/admin club edit page for name/slug editing or, if creation already exists, extend the creation/edit flow with slug controls.
- [ ] 011 Implement live validity/availability feedback for staff slug editing, either in LiveView or via a small admin-only validation endpoint.
- [ ] 012 Add host-based public club-page resolution for `*.clubs.memba.io`:
- [ ] 013 Update seeds, fixtures, acceptance support, and tests to create clubs with slugs.
- [ ] 014 Add tests for:
- [ ] 015 Run `dev check`.
