Implemented and checked off task 002:

> `- [x] 002 Evolve new-group creation to carry it, and append idempotent email-slug facts for existing Everyone and Admin groups without rewriting historic group events.`

Changes made:

- Extended [`CreateGroup`](/workspace/memba/web/lib/memba/membership/commands/create_group.ex:1) with `email_slug`.
- Updated the [`Club` aggregate](/workspace/memba/web/lib/memba/membership/club.ex:123) so:
  - new groups with a slug emit `GroupCreated` followed by a normalized `GroupEmailSlugAssigned`;
  - matching historical groups emit only the missing slug-assignment fact;
  - replaying the same command after assignment emits no events;
  - duplicate slugs are rejected before group creation.
- Kept `GroupCreated` unchanged, preserving historical event compatibility.
- Added aggregate, command-shape, event-store dispatch, normalization, uniqueness, and idempotency coverage in:
  - [`club_test.exs`](/workspace/memba/web/test/memba/membership/club_test.exs:350)
  - [`create_club_dispatch_test.exs`](/workspace/memba/web/test/memba/membership/create_club_dispatch_test.exs:104)
  - [`group_command_event_modules_test.exs`](/workspace/memba/web/test/memba/membership/group_command_event_modules_test.exs:33)
- Left normal new-club and release-backfill wiring unchanged for task 003.

Validation:

- Initial focused red run failed because `CreateGroup` had no `email_slug`.
- Focused implementation tests: 44 tests, 0 failures.
- Membership projection/backfill/replay and Messaging reply regressions: 64 tests, 0 failures.
- `mix format …`: passed.
- `git diff --check`: passed.
- `dev check --quick` ran, but ExUnit reported the already-documented `DevTestSupportControllerTest` consistency timeout: 1,099 tests, 1 failure. The isolated six-test controller suite reproduced the same timeout. This is the pre-existing failure identified during task 001, so I did not alter that unrelated code or claim a clean quick-check result.

Only [`todo.md` task 002](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:4) was checked off. No tasks were split, added, removed, or reordered.

ADR conformance:

- ADR 0002: behavior remains command/aggregate/event modeled.
- ADR 0007: all implementation stays within Membership.
- ADRs 0008/0009: historical events remain immutable; missing state is appended as a new event and projected normally.
- ADR 0011: caller-generated UUID identities are unchanged.
- ADR 0017: no migration or historical release artifact was rewritten.
- ADRs 0021/0022: existing committed projection publication remains intact, and integration tests use strong consistency without timing sleeps.