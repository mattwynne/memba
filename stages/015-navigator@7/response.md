The selected scenario is green. The final WIP run reported `1 test, 0 failures`, and the supporting suites and full quality gate passed.

I removed only its `@wip` tag, preserving `@iteration-068` and every assertion. The now-untagged scenario passed through the ordinary domain runner:

`132 tests, 0 failures, 131 excluded`

The exact focused command and evidence are recorded in [change.md](/workspace/memba/.fabro/tmp/bdd/change.md) for refactoring. The final full check still needs to run after any cleanup on the exact tagless state.

{"preferred_next_label":"refactor"}