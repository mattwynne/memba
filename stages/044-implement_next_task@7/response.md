Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 007 Update the club projector to write `slug` from `ClubCreated` events.`

2. **Changes made**
   - Updated `Memba.Membership.Projectors.Club` to insert `slug: event.slug` into the club projection.
   - Updated `Memba.Membership.Projections.Club` so `slug` is a persisted schema field, not virtual.
   - Updated `web/test/memba/membership/club_projection_test.exs` to prove a `ClubCreated` event slug (`kmc`) is projected and read back through `Membership.get_club/1`.
   - Updated Cucumber authentication test support to create scenario-scoped valid slugs when it creates clubs through `Membership.create_club/2`. This was necessary because persisting event slugs exposed duplicate default slugs across multiple independent scenarios executed in one ExUnit test.
   - No acceptance feature files were changed.

3. **Validation commands run**
   - `mix format --check-formatted ... && mix test test/memba/membership/club_projection_test.exs`
     - Passed: `3 tests, 0 failures`.
   - `mix format --check-formatted ... && mix test test/memba/membership/club_projection_test.exs test/features/cucumber_configuration_test.exs`
     - Passed: `8 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `270 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 Update the club projector to write `slug` from `ClubCreated` events.`
   - To:
     - `- [x] 007 Update the club projector to write `slug` from `ClubCreated` events.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007: Stayed within the Membership bounded context; Messaging remains dependent only on Membership query APIs.
   - ADR 0008: Continued using the same Postgres database with normal Ecto projection tables.
   - ADR 0009: Used the existing Commanded Ecto projector path rather than custom projection plumbing.
   - ADR 0011: Preserved `club_id` as aggregate/projection identity; `slug` is a projected public attribute, not an identity replacement.