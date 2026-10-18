Implemented the assigned historical-name no-op repair without changing the acceptance scenario or publishing anything.

- Identical normalized rename targets now return an eventless no-op before applying the 100-grapheme rename limit in [person.ex](/workspace/memba/web/lib/memba/membership/person.ex:65).
- Added historical `PersonCreated` coverage for a 101-grapheme name in [person_test.exs](/workspace/memba/web/test/memba/membership/person_test.exs:219).
- Expected red proof: 25 tests, 1 failure.
- Aggregate verification: 25 tests, 0 failures.
- Live-query regression suite: 46 tests, 0 failures.
- Selected acceptance scenario: 132 tests, 0 failures, 131 excluded.
- `git diff --check` passed.
- Manual and independent reviews found no issues.
- Scenario wording and `@iteration-068` tag remain unchanged; no `@wip` exists.

Full command results and log paths are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md). The full `dev check` was intentionally left for the navigator, as required by the assignment. No commit or publication was made.