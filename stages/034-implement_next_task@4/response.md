Implemented task 015 and left it unchecked for independent review.

1. Selected task

`- [ ] 015 Use server-side live validation/preview, rechecking at submit, with accessible field associations.`

2. Changes made

- Added an authenticated, advisory `Membership.preview_custom_group/1` API in [membership.ex](/workspace/memba/web/lib/memba/membership.ex:78).
  - Validates the current actor’s club-management permission.
  - Checks projected club-local name uniqueness.
  - Uses the same name normalization and `CustomGroupSlug` allocator as authoritative creation.
  - Returns the generated address and collision context without reserving anything.
- Centralized the existing nonblank, trimmed display-name rule in [group_name.ex](/workspace/memba/web/lib/memba/membership/group_name.ex:1) and reused it from the Club aggregate in [club.ex](/workspace/memba/web/lib/memba/membership/club.ex:64).
- Extended [new.ex](/workspace/memba/web/lib/memba_web/live/member_group_live/new.ex:1) with:
  - server-side `phx-change` validation;
  - neutral untouched-blank state and edited-blank feedback;
  - case/outer-space-insensitive duplicate feedback;
  - live normal, suffixed, and Unicode-fallback address previews;
  - collision explanations;
  - disabled submit while invalid;
  - a retry-stable group ID for the form session;
  - authoritative `Membership.create_custom_group/2` submission and aggregate error handling;
  - accessible label, hint, error, output, live-region, and collision-note associations.
- Expanded [new_test.exs](/workspace/memba/web/test/memba_web/live/member_group_live/new_test.exs:1) to prove typing, clearing, duplicate correction, non-persistence during preview, suffix allocation, Unicode fallback, ARIA relationships, and stale-preview rejection at the Club boundary.

3. Validation

- TDD red run: 7 tests, 3 expected behavior failures before implementation.
- Focused LiveView/PhoenixTest suite: 7 tests, 0 failures.
- LiveView plus Club/custom-group/domain regression set: 81 tests, 0 failures.
- `dev check --quick`: 1,328 tests, 0 failures.
- Focused `mix format --check-formatted`: passed.
- `git diff --check`: passed.

The workflow’s final task still owns the explicit full `dev check` run.

4. Todo state

The selected line remains unchanged and unchecked in [todo.md](/workspace/memba/docs/iterations/062-create-custom-groups/todo.md:17):

`- [ ] 015 Use server-side live validation/preview, rechecking at submit, with accessible field associations.`

5. Todo changes

None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

- ADR 0013: user-visible typing and validation behavior is covered through PhoenixTest, with lower-level LiveView coverage for the stale-submit race.
- ADR 0015: the interactive member form remains LiveView-owned.
- ADR 0019: previews use the club’s canonical slug, and successful navigation preserves club-host routing.
- ADR 0022: authoritative submission requests strong projection consistency before navigating to projection-backed group state.
- ADR 0023: successful creation targets the existing URL-addressable Members route.
- ADR 0024: projection-backed preview is explicitly advisory; authority, uniqueness, slug allocation, and creation are rechecked inside the Club aggregate’s serialized boundary.