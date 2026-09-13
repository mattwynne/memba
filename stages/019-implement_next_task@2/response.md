Implemented task 002 and left it unchecked for independent review.

1. Selected todo line

`- [ ] 002 Validate current active admin authority, same-club identity, group-name uniqueness and slug allocation inside that serialized boundary.`

2. Changes made

- Updated the [Club aggregate](/workspace/memba/web/lib/memba/membership/club.ex:112) to reject duplicate group names using trimmed, case-insensitive comparison against all groups in the authoritative Club state, including Everyone and Admin.
- Kept authorization and allocation within the Club command decision. An actor who is an Admin elsewhere but only an ordinary member of the destination club remains unauthorized.
- Confirmed slug allocation is club-local and considers custom and system-group slugs, selecting the first available suffix.
- Expanded [custom-group dispatch tests](/workspace/memba/web/test/memba/membership/create_custom_group_dispatch_test.exs:167) for:
  - same-club authorization;
  - duplicate case/space variants;
  - protected system names;
  - cross-club name and slug independence;
  - custom and system slug collisions;
  - non-ASCII display names and fallback slugs.
- Added focused [slug allocator tests](/workspace/memba/web/test/memba/membership/custom_group_slug_test.exs:1) for suffix gaps, 32-character truncation, address validity, and fallback allocation.

3. Validation

- TDD red run: 14 tests, 3 failures, confirming the missing uniqueness behavior and exposing one test-fixture setup issue.
- Focused tests: 14 tests, 0 failures.
- Full Membership context: 304 tests, 0 failures.
- `mix format --check-formatted` passed for all touched files.
- `PATH="$PWD/bin:$PATH" dev check --quick`: 1,306 tests, 0 failures.
- `git diff --check`: passed.

4. Todo state

The selected line remains unchanged and unchecked:

`- [ ] 002 Validate current active admin authority, same-club identity, group-name uniqueness and slug allocation inside that serialized boundary.`

5. Todo changes

No tasks were split, added, removed, reordered, or checked.

6. ADR conformance

- ADR 0002: uniqueness and allocation are aggregate decisions derived from event-replayed state.
- ADR 0007: behavior remains entirely within Membership’s public API and bounded context.
- ADR 0011: caller-generated typed group and person identities remain intact.
- ADR 0024: authorization, name uniqueness, and slug allocation are enforced on the Club stream, without projection-backed authority or preflight decisions.