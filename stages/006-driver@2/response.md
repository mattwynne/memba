Implemented the scoped conditional Person rename write path without publishing or changing the agreed feature text/tags.

- Added actor-authorized `RenamePerson` preparation, routing, dispatch, aggregate handling, and `PersonRenamed`.
- Added normalization, Unicode grapheme limits, stale-name conflict detection, and eventless identical-target behavior.
- Added only the intervening rename Given step, preserving the older edit baseline.
- Kept projector, readback, UI conflict handling, and later scenario steps out of scope.
- Focused Person suites: 36 tests, 0 failures.
- Router registration suite: 3 tests, 0 failures.
- Final `dev test:wip`: exactly one scenario ran and stopped at the predicted next undefined step, `When Alice submits the older change to "Alice Brown"`; exit 2.
- Review found no issues within the assigned slice.
- `dev check` was not run because the required WIP observation reached the predicted incomplete-scenario boundary where implementation had to stop.

Full evidence and log paths are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md).