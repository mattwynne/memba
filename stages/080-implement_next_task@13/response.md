Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 013 Update seeds, fixtures, acceptance support, and tests to create clubs with slugs.`

2. **Changes made**
   - Added `web/test/support/membership_fixtures.ex`:
     - `membership_club_attrs/1`
     - `membership_club_slug/2`
     - `insert_membership_club!/1`
     - Generates deterministic, valid, unique-ish fixture slugs from club name + club UUID.
   - Imported the fixture helpers into:
     - `Memba.DataCase`
     - `Memba.EventSourcedCase`
     - `MembaWeb.ConnCase`
     - `MembaWeb.FeatureCase`
   - Updated Elixir test helpers and setup paths that create projected clubs so they now supply/store slugs explicitly instead of relying on database defaults.
   - Updated acceptance support:
     - `createClub` now fills the “Club slug” field, stores the slug in `world.clubs`, and supports explicit slug overrides.
     - Acceptance support tests now include slug-bearing club state.
   - Updated Cucumber config unit expectations so `staff_club_slugs.feature` remains intentionally skipped via `@wip`.
   - `web/priv/repo/seeds.exs` contains no seeded club creation, so there was no seed club to update.
   - No acceptance feature files were modified.

3. **Validation run**
   - `cd web && mix format --check-formatted` — passed.
   - `cd acceptance-tests && npm_config_cache=../.npm-cache node --test test/*.test.js` — passed: `40 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check` — passed: `291 tests, 0 failures`.
   - `git diff --check` — passed.
   - Note: npm dependencies were installed temporarily for the acceptance support unit tests and removed afterward; no dependency artifacts remain tracked.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 013 Update seeds, fixtures, acceptance support, and tests to create clubs with slugs.`
   - To:
     - `- [x] 013 Update seeds, fixtures, acceptance support, and tests to create clubs with slugs.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: stays within Phoenix/Elixir app and test stack.
   - ADR 0003 / 0010: keeps shared Cucumber feature files untouched and confirms `staff_club_slugs.feature` remains deferred via `@wip`.
   - ADR 0007: uses Membership-owned fixture helpers and public Membership APIs where event-sourced creation is needed.
   - ADR 0011: preserves caller-generated UUID club identities; slugs are data attributes, not aggregate identities.
   - ADR 0013: acceptance/browser support tests continue to exercise user-visible setup helpers and app-facing state.