Implemented the scoped review repair without publishing.

- Added a deterministic simultaneous-dispatch test in [person_command_dispatch_test.exs](/workspace/memba/web/test/memba/membership/person_command_dispatch_test.exs:199).
- Both real rename commands are prepared from the same baseline, wait in supervised tasks, and are released only after both report readiness.
- The test proves exactly one rename succeeds, the loser reports the winner in `:name_conflict`, and the projection retains that winner.
- No production code, feature scenarios, tags, or unrelated tests changed.
- Independent review found no issues.

Validation:

- Pre-edit dispatch baseline: 6 tests, 0 failures.
- Post-edit dispatch tests: 7 tests, 0 failures.
- Selected acceptance scenario: 1 included, passing; 132 tests, 0 failures, 131 excluded.
- `git diff --check`: passing.
- Full `dev check` was intentionally left to the navigator as required by the repair assignment.

Complete command results, log paths, formatter-attempt notes, and reconsiderations are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md:1).