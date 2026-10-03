Packet `task-008a-3971e31-coherent-audit-revision-8` is `ready_for_review`.

Implemented:

- Repaired dashboard and conversation-detail audit fixtures to use coherent root message/conversation identities.
- Added exact complete-interest assertions: 31 dashboard interests and 13 detail interests, including the detail root message and represented author.
- Preserved all eleven projector-family intersections and Membership loader-count behavior.
- Corrected legacy Membership recovery documentation to retained-`MembershipProjection`-row-only, failing closed when scope cannot be recovered.
- Left task 008A unchecked, as required.

Changed implementation paths:

- [memba_read_model_source_test.exs](/workspace/memba/web/test/memba_web/live_query/memba_read_model_source_test.exs:484)
- [migration-matrix.md](/workspace/memba/docs/iterations/067-live-projection-queries/migration-matrix.md:161)

Validation passed:

- Adapter/Binding tests: 46 tests, 0 failures
- Dashboard/detail query tests: 8 tests, 0 failures
- `bin/mix format --check-formatted`
- `git diff --check`

The required result artifact is valid JSON at [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json:1). No unresolved items remain. Full `dev check` was not run because this packet explicitly reserves that unscoped gate for the workflow’s deterministic validation node.