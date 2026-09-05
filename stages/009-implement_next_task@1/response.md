Implemented and checked off task 001:

> `- [x] 001 Extend the Membership group write model, events, state, and projections with an immutable normalised email slug, unique per club.`

Changes made:

- Added the internal [`AssignGroupEmailSlug`](/workspace/memba/web/lib/memba/membership/commands/assign_group_email_slug.ex) command and [`GroupEmailSlugAssigned`](/workspace/memba/web/lib/memba/membership/events/group_email_slug_assigned.ex) event.
- Extended the [`Club` aggregate](/workspace/memba/web/lib/memba/membership/club.ex:35) to:
  - normalize email slugs by trimming and lowercasing;
  - reject invalid slugs;
  - enforce uniqueness within a club;
  - make assignment immutable;
  - treat repeated assignment of the same normalized slug as idempotent;
  - maintain group and reverse-index state during replay.
- Registered the command with the Membership router.
- Added `email_slug` to the Membership group projection and projected assignment events without allowing later events to overwrite a different slug.
- Generated [`20260905070851_add_email_slug_to_membership_groups.exs`](/workspace/memba/web/priv/repo/migrations/20260905070851_add_email_slug_to_membership_groups.exs:1), adding the nullable column and a partial unique `(club_id, email_slug)` index. Nullable projection state preserves replay compatibility until the later backfill task.
- Added aggregate, command/event serialization, router-registration, projection, normalization, immutability, and club-scoped uniqueness coverage.
- Updated only [task 001 in todo.md](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:3). No tasks were split, added, or reordered. `CreateGroup`, system-group assignment, and backfill remain for tasks 002–003.

Validation:

- TDD red run failed as expected because `AssignGroupEmailSlug` did not yet exist.
- `dev test test/memba/membership/club_test.exs test/memba/membership/group_command_event_modules_test.exs test/memba/membership/group_projection_test.exs` — 37 tests, 0 failures.
- `dev test test/memba/membership/app_test.exs` — 3 tests, 0 failures.
- `mix format --check-formatted ...` for every touched Elixir file — passed.
- `ERL_FLAGS='+S 12:12' PATH="$PWD/bin:$PATH" dev check --quick` — 1,092 tests, 0 failures. The scheduler override avoids the sandbox’s low-core SQL pool starvation; an earlier default eight-scheduler run exposed that resource issue plus the now-fixed command registry expectation.
- The validated task diff is staged for Fabro’s checkpoint; no manual commit was created.

ADR conformance:

- ADR 0002: behavior is modeled through a Commanded command, Club aggregate invariant, and append-only domain event.
- ADR 0007: all changes remain inside Membership; no Messaging projection-table dependency was introduced.
- ADR 0009: query state is maintained through the existing Commanded Ecto group projector.
- ADR 0011: caller-supplied club and group IDs remain unchanged.
- ADR 0021: the existing post-commit read-model publication boundary remains intact.
- Historic `GroupCreated` events were not modified; email-slug assignment is a separate fact, preserving replay and event-history compatibility.