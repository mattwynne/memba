Implemented the selected Person rename foundation without changing feature wording or tags.

- Added `RenamePerson` / `PersonRenamed`, aggregate validation and concurrency handling, command routing, projection, and exact Person-scoped live-query invalidation.
- Added self-only `PersonCommands.prepare_rename/2`.
- Added the real command/projector-backed `{word} is known as {string}` Cucumber step.
- Added focused aggregate, preparation, dispatch/projection, and live-query tests.
- Post-format supporting run: 83 tests, 0 failures.
- Final `bin/dev test:wip`: exit 2, exactly one scenario and one failure at the predicted next undefined conversation step.
- Did not run `bin/dev check`, remove `@wip`, or publish.

Full command evidence and the formatter ownership caveat are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md).