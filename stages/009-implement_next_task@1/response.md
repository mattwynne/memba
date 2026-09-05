Implemented and checked off task 001:

> `- [x] 001 Extend the Membership group write model, events, state, and projections with an immutable normalised email slug, unique per club.`

Changes made:

- Added the internal [`AssignGroupEmailSlug`](/workspace/memba/web/lib/memba/membership/commands/assign_group_email_slug.ex:1) command and JSON-serializable [`GroupEmailSlugAssigned`](/workspace/memba/web/lib/memba/membership/events/group_email_slug_assigned.ex:1) event.
- Extended the [`Club` aggregate](/workspace/memba/web/lib/memba/membership/club.ex:35) to:
  - normalize slugs before assignment;
  - retain slugs in group state and a reverse lookup map;
  - permit idempotent reassignment of the same normalized slug;
  - reject changing an assigned slug;
  - reject duplicate slugs within a club.
- Registered the command through the Membership router.
- Extended the group Ecto schema and projector to persist assignment events.
- Generated a new reversible [migration](/workspace/memba/web/priv/repo/migrations/20260905001129_add_email_slug_to_membership_groups.exs:1) adding a nullable `email_slug` column and partial unique `(club_id, email_slug)` index. Nullability preserves historical-event replay until later backfill tasks run.
- Added aggregate, command/event serialization, router-registration, projection, normalization, immutability, and uniqueness tests.
- Left `CreateGroup`, system-group slug assignment, backfill, and public lookup untouched for tasks 002/003.
- Updated only [todo.md task 001](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:3). No todo splitting or reordering was needed.

Validation:

- Focused TDD red run failed because `AssignGroupEmailSlug` did not exist yet.
- `PATH="$PWD/bin:$PATH" dev test test/memba/membership/group_command_event_modules_test.exs test/memba/membership/club_test.exs test/memba/membership/group_projection_test.exs test/memba/membership/app_test.exs`
  - Final result: 43 tests, 0 failures.
- `mix format …`
  - Passed.
- `git diff --check`
  - Passed.
- `PATH="$PWD/bin:$PATH" dev check --quick`
  - Ran twice, but its log contained one existing `DevTestSupportControllerTest` consistency-timeout failure among 1,095 tests. The same 6-test suite failed identically on untouched `HEAD` in an isolated baseline worktree, confirming it is pre-existing and unrelated to task 001. I did not modify that unrelated test under the task ownership rules, so I am not claiming a clean quick-check result.

ADR conformance:

- ADR 0002: slug assignment is modeled through a command, aggregate invariant, immutable event, and reconstructed state.
- ADR 0007: all changes remain inside Membership; Messaging does not access Membership storage.
- ADRs 0008/0009: the fact remains in EventStore and is projected through the existing Commanded Ecto projector.
- ADR 0011: UUID aggregate/group identities remain unchanged; the slug is only a routing attribute.
- ADR 0017: a new migration was generated instead of editing an already-applied migration.
- ADR 0021: the projector retains its committed `after_update/3` publication.
- ADR 0022: projection assertions use strong-consistency dispatch rather than timing sleeps.