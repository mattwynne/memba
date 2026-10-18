Implemented the single stale-name conflict scenario without editing the agreed feature or removing `@wip`.

The change adds:

- Conditional `RenamePerson` / `PersonRenamed` behavior with normalized names and 100-grapheme validation.
- Trusted self-target command preparation.
- Aggregate-level stale-name detection and conditional confirmation.
- Person projection and exact live-query invalidation.
- Native domain Cucumber steps using the real command/event/projection/query path.
- Focused authorization, replay, projection, and boundary tests.

Validation results:

- Supporting suite: 83 tests, 0 failures.
- `dev check`: exit 0, including 7 browser scenarios and 113 steps.
- Final `dev test:wip`: exactly 1 test, 0 failures; exited 1 with the expected green guard:
  `This scenario now passes. Remove its @wip tag.`

The tag remains for the navigator, and nothing was published. Full command results and log paths are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md).