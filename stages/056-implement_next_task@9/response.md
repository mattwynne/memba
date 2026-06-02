Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 009 Add Membership.get_club_by_slug/1, using normalized lookup input only where safe and returning nil for invalid/unknown values.`

2. **Changes made**
   - Added `Memba.Membership.get_club_by_slug/1`.
     - Looks up `Memba.Membership.Projections.Club` by `slug`.
     - Returns the projected club for known valid slugs.
     - Returns `nil` for invalid, unknown, or non-string values.
   - Added `Memba.Membership.Slug.normalize_for_lookup/1`.
     - Safely trims surrounding whitespace and downcases lookup input.
     - Does **not** kebab-case or rewrite unsafe characters.
     - Reuses existing slug validation.
   - Added tests covering:
     - lookup by exact valid slug;
     - lookup with safe normalization like `" KMC "` → `"kmc"`;
     - `nil` for unknown/invalid/non-string lookup values;
     - slug lookup normalization behaviour itself.

3. **Validation commands run**
   - `cd web && mix format --check-formatted` — passed.
   - `git diff --check` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed:
     - `277 tests, 0 failures`.
   - Note: I also attempted a targeted bare-shell `mix test` run with a manually started dev Postgres port, but Postgres was not reachable from that shell setup. Final validation was completed through the required `dev check`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 009 Add Membership.get_club_by_slug/1, using normalized lookup input only where safe and returning nil for invalid/unknown values.`
   - To:
     - `- [x] 009 Add Membership.get_club_by_slug/1, using normalized lookup input only where safe and returning nil for invalid/unknown values.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0007: Kept the query inside the Membership bounded context public API.
   - ADR 0008: Continued using persistent Postgres/EventStore-backed test paths via `dev check`.
   - ADR 0009: Queried the existing Ecto projection/read model; no custom projection infrastructure added.
   - ADR 0011: Preserved `club_id` as aggregate identity; slug is only a public lookup attribute.