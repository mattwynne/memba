Implemented the task 006 revision and resolved the Unicode normalization mismatch.

1. Selected todo line

`- [ ] 006 Extend aggregate state/projection constraints only as necessary for normalized name uniqueness; keep projections as projections.`

2. Changes made

- Preserved the event-rehydrated aggregate name index and shared Unicode-aware normalization in `GroupName`.
- Added `name_uniqueness_key` to the [group projection](/workspace/memba/web/lib/memba/membership/projections/group.ex:14).
- Updated the [group projector](/workspace/memba/web/lib/memba/membership/projectors/group.ex:16) to derive the key through `GroupName.uniqueness_key/1` for both inserts and replay/upsert updates.
- Reworked the [migration](/workspace/memba/web/priv/repo/migrations/20260913221054_add_normalized_group_name_uniqueness.exs:4) to:
  - add the stored key;
  - backfill all existing projection rows using trim-and-Unicode-downcase semantics;
  - make the key non-null;
  - enforce club-scoped uniqueness on `{club_id, name_uniqueness_key}`.
- Removed reliance on PostgreSQL `lower(btrim(name))`, whose `C`-collation behavior disagreed with Elixir for values such as `Σ` and `σ`.
- Added non-ASCII aggregate and projection regressions in [club_test.exs](/workspace/memba/web/test/memba/membership/club_test.exs:846) and [group_projection_test.exs](/workspace/memba/web/test/memba/membership/group_projection_test.exs:138).
- Updated existing direct read-model test fixtures to provide the now-required derived key. No acceptance feature files changed.

3. Focused validation

- TDD red run failed on the missing projection field as expected.
- Focused tests:
  - `dev test test/memba/membership/club_test.exs test/memba/membership/create_custom_group_dispatch_test.exs test/memba/membership/group_projection_test.exs test/memba/messaging/inbound_club_destination_test.exs`
  - 80 tests, 0 failures.
- `mix format --check-formatted ...`
  - Passed for all touched Elixir files.
- `dev check --quick`
  - 1,311 tests, 0 failures.
- `git diff --check`
  - Passed.
- The full browser-inclusive `dev check` remains owned by the workflow’s final validation stage.

4. Todo state

The selected line remains unchanged and unchecked for independent review:

`- [ ] 006 Extend aggregate state/projection constraints only as necessary for normalized name uniqueness; keep projections as projections.`

5. Todo changes

None. No tasks were split, added, removed, reordered, or checked.

6. ADR conformance

- ADR 0002 and ADR 0024: authoritative uniqueness remains in replayable Club aggregate state.
- ADR 0009: PostgreSQL stores a rebuildable projection key and supplies a defensive read-model uniqueness constraint.
- ADR 0007: all behavior remains within the Membership context.
- ADR 0011: caller-generated identities and retry semantics are unchanged.
- Historical events remain immutable; replay derives both aggregate and projection keys from existing `GroupCreated` facts.