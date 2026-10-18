Implemented the assigned `PersonRenamed` live-query repair without publishing or changing the acceptance scenario.

- Added explicit classification requiring `person_id` and returning only `[{:person, person_id}]` in [memba_read_model_source.ex](/workspace/memba/web/lib/memba_web/live_query/memba_read_model_source.ex:207).
- Extended the Person event-family regression coverage while preserving existing email invalidations in [memba_read_model_source_test.exs](/workspace/memba/web/test/memba_web/live_query/memba_read_model_source_test.exs:998).
- Regression proof before implementation: 46 tests, 1 expected failure.
- Final adapter suite: 46 tests, 0 failures.
- Focused acceptance scenario: 132 tests, 0 failures, 131 excluded; exactly the selected scenario ran.
- `git diff --check` passed.
- Independent review found no issues.
- The separate historical overlength-name finding remains untouched and queued.
- Full `dev check` was intentionally deferred as required by the assignment.

Complete command results and log paths are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md). No commit or publish was performed.