Implemented and checked off task 016:

> `016 Cover slug uniqueness and safe re-runs of the slug backfill.`

Changes:

- Strengthened [system_groups_backfill_test.exs](/workspace/memba/web/test/memba/membership/system_groups_backfill_test.exs:68) to count `GroupEmailSlugAssigned` events during normal, interrupted, and release-level backfill reruns.
- Added a focused historical-system-group rerun assertion proving the second backfill dispatches no slug commands and leaves exactly two slug facts.
- Confirmed existing coverage already enforces normalized per-club uniqueness at both the aggregate and database-index layers; no production-code change was needed.
- Checked off exactly [todo.md](/workspace/memba/docs/iterations/057-admin-group-email-conversations/todo.md:18):
  ```markdown
  - [x] 016 Cover slug uniqueness and safe re-runs of the slug backfill.
  ```

Validation:

- `dev test test/memba/membership/system_groups_backfill_test.exs test/memba/membership/club_test.exs test/memba/membership/group_projection_test.exs`
  - `47 tests, 0 failures`
- `git diff --check`
  - Passed.
- `dev check --quick`
  - The wrapper returned exit status 0 on the latest run, but ExUnit reported `1123 tests, 1 failure`, so I am not treating it as a clean pass.
  - The failure is the existing `DevTestSupportControllerTest` reset regression: the Person projector encountered a database connection queue timeout after reset and caused a strong-consistency timeout. It is outside task 016’s backfill coverage.

No todo tasks were split, added, removed, or reordered. Tasks 017 and 018 remain unchecked.

ADR conformance remains intact: slug facts stay immutable event-sourced state under ADR 0002, uniqueness is enforced in the aggregate and Ecto projection under ADR 0009, release reruns remain restartable under ADR 0017, and tests use projection synchronization rather than sleeps in accordance with ADR 0022.