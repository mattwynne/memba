Packet `task-008d1-f0f68f4-group-participant-eligibility-1` is `ready_for_review`.

Implemented:

- Extended [`list_active_members_of_group`](/workspace/memba/web/lib/memba/membership.ex:1024) to accept optional `include_without_primary_email: true`.
- Existing one-argument callers retain recipient-only behavior.
- Explicit eligibility mode includes active participants with a projected Person but no primary-email row, returning the existing plain-map shape with `email: nil`.
- Preserved active group/club membership filtering, group isolation, projected-Person requirements, deterministic name/Person-ID ordering, and alphabetical role ordering.
- Added focused coverage in [query_test.exs](/workspace/memba/web/test/memba/membership/query_test.exs:285) for both modes, ordering, roles, invalid IDs, inactive/mismatched memberships, other groups, and missing Person projections.
- Left task 008D1 unchecked. No compose query, LiveView, adapter, package, schema, projector, ADR, matrix, plan, todo, or acceptance feature was changed.

Validation:

- Focused combined regression: `51 tests, 0 failures`
- Format check: passed
- `git diff --check`: passed
- Worker result JSON: parsed successfully

The required artifact is at [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json). Full `dev check` was intentionally not run because this packet reserves that gate for the deterministic workflow.