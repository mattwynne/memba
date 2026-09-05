Implemented and checked off task 002:

> `- [x] 002 Evolve new-group creation to carry it, and append idempotent email-slug facts for existing Everyone and Admin groups without rewriting historic group events.`

1. Changes made

- Extended [`CreateGroup`](/workspace/memba/web/lib/memba/membership/commands/create_group.ex:1) with an optional `email_slug`.
- Updated the [`Club` aggregate](/workspace/memba/web/lib/memba/membership/club.ex:123) so:
  - new groups with an email slug emit `GroupCreated` followed by the separate `GroupEmailSlugAssigned` fact;
  - slugs are normalized and checked against the existing uniqueness and immutability invariants;
  - repeating `CreateGroup` for an existing matching group appends its missing slug fact;
  - repeating it after assignment emits no events;
  - legacy callers without a slug retain their existing behavior.
- Kept `GroupCreated` unchanged, preserving historic event serialization and replay compatibility.
- Added aggregate and application-dispatch coverage in [`club_test.exs`](/workspace/memba/web/test/memba/membership/club_test.exs:350) and [`create_club_dispatch_test.exs`](/workspace/memba/web/test/memba/membership/create_club_dispatch_test.exs:132), including Everyone/Admin idempotency and event-stream counts.
- Updated command-shape coverage to prove `CreateGroup` carries the slug.

2. Validation

- Initial TDD run failed as expected because `CreateGroup` had no `email_slug` field.
- `dev test test/memba/membership/club_test.exs test/memba/membership/group_command_event_modules_test.exs test/memba/membership/create_club_dispatch_test.exs` — 41 tests, 0 failures.
- `mix format --check-formatted ...` for all touched Elixir files — passed.
- `git diff --check` — passed.
- `ERL_FLAGS='+S 12:12' PATH="$PWD/bin:$PATH" dev check --quick` — 1,095 tests, 0 failures.

3. Todo state

Only [task 002](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:4) was checked off. No tasks were split, added, removed, or reordered. Task 003 still owns wiring the new-club and release-backfill callers to supply `everyone` and `admin`.

4. ADR conformance

- ADR 0002: creation and assignment remain Commanded aggregate decisions expressed through append-only domain events.
- ADR 0007: all behavior remains within Membership; no Messaging or projection-storage dependency was introduced.
- ADR 0009/0021: existing Ecto projection and post-commit publication paths continue handling `GroupEmailSlugAssigned` unchanged.
- ADR 0011: caller-supplied club and group identities remain intact.
- Event-history compatibility is preserved by adding a separate slug fact instead of changing historic `GroupCreated` events.

The validated diff is staged for Fabro’s checkpoint; no manual commit was created.