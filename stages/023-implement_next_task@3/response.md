Implemented and checked off task 003:

> `- [x] 003 Make new-club system-group creation and the release backfill assign everyone and admin consistently. Expose a public Membership lookup by club and group email slug; Messaging must not query Membership schemas directly.`

Changes made:

- Added explicit, stable `everyone` and `admin` email-slug definitions in [system_groups.ex](/workspace/memba/web/lib/memba/membership/system_groups.ex:8), keeping routing slugs distinct from internal group keys.
- Updated new-club creation in [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:69) to emit a separate `GroupEmailSlugAssigned` fact immediately after each system group’s `GroupCreated` fact.
- Added `Membership.get_group_by_email_slug/2` in [membership.ex](/workspace/memba/web/lib/memba/membership.ex:526). It:
  - validates the club ID;
  - safely normalizes the slug;
  - scopes lookup to the club;
  - returns a plain public map rather than exposing the Membership projection schema;
  - returns `nil` for invalid or unknown input.
- Extended the release-backfill source query to detect both absent groups and existing groups missing their expected slug.
- Updated [backfill.ex](/workspace/memba/web/lib/memba/membership/system_groups/backfill.ex:123) to carry the slug through the existing idempotent `CreateGroup` command.
- Made the Club projector advance over slug-assignment facts so projection barriers remain valid.
- Updated aggregate versions and exact event expectations affected by the two additional creation facts.
- Added coverage for new-club slugs, historical unslugged system groups, lookup normalization and club scoping, and plain-map API results.

Validation:

- Initial TDD run: 73 tests, 6 expected failures.
- Focused implementation suite: 73 tests, 0 failures.
- Entire Membership suite: 259 tests, 0 failures.
- Projection-barrier regression: 2 tests, 0 failures.
- Touched-file formatting check: passed.
- `git diff --check`: passed.
- Confirmed production Messaging code contains no direct Membership projection/schema queries.
- Final `dev check --quick`: 1,102 tests, 1 failure. The remaining failure is the pre-existing `DevTestSupportControllerTest` DB sandbox/consistency timeout documented by tasks 001–002; the task-related projection-barrier failure found on the first broad run was fixed and now passes independently.

Only [todo.md task 003](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:5) was checked off. No tasks were split, added, removed, or reordered.

ADR conformance:

- ADR 0002: slug assignment remains command/aggregate/event modeled.
- ADR 0007: the lookup is owned by Membership and returns plain public data; Messaging does not query Membership storage.
- ADRs 0008/0009: historical group events remain immutable, with missing routing state appended and projected as a separate fact.
- ADR 0011: deterministic system-group identities remain unchanged.
- ADR 0017: the existing release service performs the restartable backfill; no historical migration was rewritten.
- ADRs 0021/0022: projector publication remains intact, and the Club projector now advances over the new facts so projection barriers continue to work.