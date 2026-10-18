Implemented and reviewed the assigned naming-only cleanup. Nothing was published.

- Renamed `@person_events` to `@person_and_email_invalidation_events` and updated its sole use in [memba_read_model_source.ex](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex:70).
- Clarified the family-coverage test description in [memba_read_model_source_test.exs](/workspace/memba/web/test/memba_web/live_query/memba_read_model_source_test.exs:1013).
- Preserved the separate `PersonRenamed` clause and all invalidation tuples, assertions, and behavior.

Validation passed:

- Required scenario before and after: `132 tests, 0 failures, 131 excluded`.
- Focused live-query suite before and after: `47 tests, 0 failures`.
- `bin/dev check`: `19` package tests and `1841` web tests passed; browser acceptance passed `7 scenarios / 113 steps`.
- `git diff --check`: passed.

The first formatting attempt used an unsupported `bin/dev mix` command and exited before modifying code. The corrected formatter invocation passed; both attempts are documented.

Full command results and log paths are in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md:1). No unresolved problems.