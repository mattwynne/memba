Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 008 Do not support replay of old slug-less `ClubCreated` events. There is no live data yet; development/test event stores may be reset or backfilled as needed.`

2. **Changes made**
   - Made `ClubCreated.slug` an enforced event struct key.
   - Updated `CreateClub` docs to describe `slug` as required.
   - Updated `Memba.Membership.Club.execute/2` to validate command slugs before emitting `ClubCreated`, preventing new slug-less events.
   - Updated `Memba.Membership.Projectors.Club` to reject invalid/slug-less `ClubCreated` events during projection instead of allowing database trigger backfill compatibility.
   - Added tests proving:
     - the aggregate rejects missing slugs;
     - the club projector rejects a slug-less `ClubCreated` replay and does not create a projection.
   - Updated direct-command test/support call sites that previously omitted slugs so current tests still model the required event shape.
   - Did not modify any `.feature` files.

3. **Validation commands run**
   - `cd web && mix format --check-formatted` — passed.
   - `PATH="$PWD/bin:$PATH" dev check` — passed: `272 tests, 0 failures`.
   - `git diff --check` — passed.
   - Note: an initial direct `mix test ...` attempt failed because Postgres was not running outside the dev wrapper; validation was rerun through the required `dev check`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 008 Do not support replay of old slug-less `ClubCreated` events. There is no live data yet; development/test event stores may be reset or backfilled as needed.`
   - To:
     - `- [x] 008 Do not support replay of old slug-less `ClubCreated` events. There is no live data yet; development/test event stores may be reset or backfilled as needed.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007: Stayed within Membership; no Messaging coupling added.
   - ADR 0008: Continued using persistent Postgres/EventStore paths and projection reset assumptions.
   - ADR 0009: Used the existing Commanded Ecto projector path; no custom projection infrastructure.
   - ADR 0011: Preserved `club_id` as the aggregate identity; `slug` remains a required public attribute, not an identity replacement.