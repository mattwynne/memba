Implemented the assigned conditional self-rename domain slice without publishing or changing the acceptance feature.

Key outcomes:

- Added `RenamePerson` and `PersonRenamed`.
- Enforced self-only command preparation from trusted actor context.
- Added Unicode whitespace normalization, 100-grapheme validation, eventless no-op behavior, stale-name conflicts, and conditional confirmation.
- Routed, dispatched, projected, and queried real Person changes.
- Added exact Person-only live-query invalidation.
- Defined all seven scenario steps using real Membership state.
- Preserved `@wip`, all other iteration-068 scenarios, and every iteration-069 example.

Validation:

- Focused Membership suite: `46 tests, 0 failures`
- Live-query suite: `47 tests, 0 failures`
- Final `dev check`: passed, including `7 scenarios, 113 steps`
- Final `bin/dev test:wip`: `1 test, 0 failures`
- The WIP wrapper exited `1` as expected with: `This scenario now passes. Remove its @wip tag.`

Full command evidence and review notes are in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md). No commit or publication was performed.