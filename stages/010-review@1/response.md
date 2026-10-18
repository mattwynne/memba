Review written to [.fabro/tmp/bdd/review.md](/workspace/memba/.fabro/tmp/bdd/review.md).

One actionable finding remains: unchanged historical names longer than 100 graphemes incorrectly fail validation instead of succeeding as an eventless no-op.

Evidence checked:

- Full supplied gate: 1,835 tests and seven browser scenarios passed.
- Selected scenario rerun on current HEAD: one included test passed.
- Focused aggregate, command, dispatch, projector, and live-query tests: 80 passed.
- Only the selected scenario’s `@wip` tag was removed; unrelated assertions and pending tags remain unchanged.
- No visual evidence was needed because this slice changes no UI or user-facing copy.
- No product code was edited or published.

{"preferred_next_label":"fix"}