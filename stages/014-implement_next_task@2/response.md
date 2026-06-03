1. **Selected todo line**
   - `002 Add a small helper for deriving the club inbound address from the existing club slug and configured inbound domain, defaulting to clubs.memba.io for this slice.`

2. **Changes made**
   - Added `web/lib/memba/club_inbound_email_address.ex`
     - New `Memba.ClubInboundEmailAddress` helper.
     - Builds `<club-slug>@<configured-domain>`.
     - Defaults domain to `clubs.memba.io`.
     - Accepts a club map with `:slug` or a slug string.
     - Normalizes lookup-style slug casing/whitespace via existing slug rules.
     - Returns `nil` for missing/invalid slugs.
   - Added default config:
     - `config :memba, :club_inbound_email, domain: "clubs.memba.io"`
   - Added focused tests:
     - `web/test/memba/club_inbound_email_address_test.exs`
   - Installed ignored acceptance-test npm dependencies with `npm ci` so full `dev check` could run locally; no tracked package files changed.

3. **Focused validation commands/results**
   - `cd web && ../bin/mix format`
     - Passed.
   - Focused helper test in clean devenv shell:
     - `mix test test/memba/club_inbound_email_address_test.exs`
     - Passed: `5 tests, 0 failures`.
   - Quick project gate:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `401 tests, 0 failures`.
   - Full project gate:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed:
       - ExUnit: `401 tests, 0 failures`
       - Acceptance: `31 scenarios (31 passed), 205 steps (205 passed)`
   - Final whitespace check:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 002 Add a small helper ...`
   - To:
     - `- [x] 002 Add a small helper ...`

5. **Todo splits/additions/reordering**
   - None. No todo lines were split, added, deleted, or reordered.

6. **ADR conformance evidence**
   - Kept this as a small pure helper/config addition, not a new event-sourced workflow or projection.
   - Used the existing Membership slug normalization rules rather than duplicating or bypassing public club slug semantics.
   - Kept club-site URL/domain configuration separate from inbound email domain configuration, consistent with ADR 0019’s distinction around club-site base domains.
   - Did not mutate Membership state or introduce Messaging CRUD paths, consistent with ADR 0007 and existing bounded-context boundaries.