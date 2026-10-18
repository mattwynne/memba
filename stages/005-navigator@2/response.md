The scenario is green, but `@wip` remains because inspection found one uncovered domain defect.

An unchanged historical name over 100 graphemes currently fails validation before the identical-target no-op check. The plan requires that identical normalized targets succeed without an event and that new validation not be applied retrospectively.

I replaced [change.md](/workspace/memba/.fabro/tmp/bdd/change.md) with one bounded repair:

- Reorder aggregate rename processing so identical targets return `[]` before the 100-grapheme limit.
- Preserve length validation for genuinely changed targets.
- Add a regression test for an unchanged legacy long name.
- Keep the already-green WIP scenario as a preservation check.

The recorded scenario, focused suites, live-query tests, and full check are genuinely green; the assignment does not invent a failing existing test.

{"preferred_next_label":"change"}