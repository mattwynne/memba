Both review findings are now resolved and verified:

- `PersonRenamed` receives exact Person-only live-query invalidation.
- An unchanged historical name over 100 graphemes takes the eventless no-op path, while genuinely different overlength names remain invalid.
- The focused aggregate suite passes 25 tests.
- The live-query adapter suite passes 46 tests.
- The selected ordinary scenario passes with exactly one scenario selected.
- The scenario retains `@iteration-068`, and no `@wip` remains.

I updated [change.md](/workspace/memba/.fabro/tmp/bdd/change.md) to hand committed HEAD `8d965d2` to the final full-check and cumulative review stages. It explicitly marks the existing `check.log` as stale because it predates the two review repairs.

{"preferred_next_label":"stop"}