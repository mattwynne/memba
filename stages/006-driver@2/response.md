Implemented the agreed legacy long-name repair without publishing or changing the acceptance scenario/tag.

- Identical normalized rename targets now return eventless success before enforcing the new 100-grapheme limit in [person.ex](/workspace/memba/web/lib/memba/membership/person.ex:65).
- Changed targets still receive length validation and existing conflict handling.
- Added replay-based coverage for an unchanged 101-grapheme historical name with a stale expected name in [person_test.exs](/workspace/memba/web/test/memba/membership/person_test.exs:449).
- Independent review found no issues or scope drift.

Validation:

- Red regression: `25 tests, 1 failure`, as predicted.
- Green regression: `25 tests, 0 failures`.
- Supporting Membership suite: `47 tests, 0 failures`.
- `dev check`: `1840 tests, 0 failures`; `7 scenarios passed`, `113 steps passed`.
- Final `dev test:wip`: exactly the assigned scenario, `1 test, 0 failures`; wrapper exit `1` only because `@wip` should now be removed by the navigator.

Full command results and log paths are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md). The `@wip` tag remains unchanged, and nothing was committed or published.