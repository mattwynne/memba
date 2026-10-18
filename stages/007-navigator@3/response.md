The scenario and supporting tests are green, including the historical long-name no-op repair. I removed only its `@wip` tag; `@iteration-068`, all assertions, and every other scenario remain unchanged.

The ordinary focused regression then passed:

- `132 tests, 0 failures, 131 excluded`
- Exit status `0`
- [ordinary-focused-after-wip.log](/workspace/memba/.fabro/tmp/bdd/ordinary-focused-after-wip.log)
- [ordinary-focused-after-wip.status](/workspace/memba/.fabro/tmp/bdd/ordinary-focused-after-wip.status)

The refactoring handoff, scenario identity, focused command, supporting tests, and behavior-preservation boundary are recorded in [change.md](/workspace/memba/.fabro/tmp/bdd/change.md). A final full check is still required on the eventual untagged post-refactoring state.

{"preferred_next_label":"refactor"}