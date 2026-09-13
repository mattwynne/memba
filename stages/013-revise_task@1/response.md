Implemented the task 001 revision and addressed the independent review’s authorization and atomicity concerns.

1. Selected todo line

`- [ ] 001 Add a thin authenticated Membership use case and actor-bearing custom-creation command, handled by the existing Club aggregate.`

2. Changes made

- Preserved the existing public `Membership.create_custom_group/2` API and actor-bearing `CreateCustomGroup` command.
- Updated the [Club aggregate](/workspace/memba/web/lib/memba/membership/club.ex:112) to authorize from authoritative aggregate state. The actor must have an active destination-club membership carrying the Admin role.
- Nonexistent, inactive, ordinary, and foreign-club actors now receive `{:error, :unauthorized}`.
- A successful decision now emits `GroupCreated`, `GroupEmailSlugAssigned`, and `GroupMemberAdded` together in one append, making the creator the first member without exposing a partial group.
- Added [CustomGroupSlug](/workspace/memba/web/lib/memba/membership/custom_group_slug.ex:1) for deterministic address-safe allocation from aggregate-owned slug state. It supports fallback stems, numeric suffixes, and the 32-character limit.
- Expanded [create_custom_group_dispatch_test.exs](/workspace/memba/web/test/memba/membership/create_custom_group_dispatch_test.exs:1) to verify the complete event batch, aggregate state, projections, creator membership, actor rejection cases, and absence of appended/projected partial groups after rejection.

3. Focused validation

- TDD red run: 6 tests, 5 expected failures before implementation.
- `dev test test/memba/membership/create_custom_group_dispatch_test.exs`: 6 tests, 0 failures.
- `dev test test/memba/membership`: 296 tests, 0 failures.
- `mix format --check-formatted ...`: passed for all candidate files.
- `dev check --quick`: 1,298 tests, 0 failures.
- `git diff --check`: passed.

The full browser-inclusive `dev check` remains owned by the workflow’s final validation stage.

4. Todo state

The exact selected line remains unchanged and unchecked:

`- [ ] 001 Add a thin authenticated Membership use case and actor-bearing custom-creation command, handled by the existing Club aggregate.`

5. Todo changes

No tasks were split, added, removed, reordered, or checked. Later lines remain pending for their broader uniqueness, concurrency, replay, and lifecycle evidence.

6. ADR conformance

- ADR 0002: custom creation remains an explicit command, aggregate decision, and immutable event batch.
- ADR 0007: all creation behavior remains inside the Membership bounded context and its public API.
- ADR 0011: the caller supplies the typed group identity before dispatch.
- ADR 0024: authorization, membership identity resolution, slug allocation, and creation are decided from Club aggregate state on the Club stream; no projection-backed authority or mutation was introduced.