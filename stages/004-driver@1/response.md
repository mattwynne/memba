Implemented the agreed stale-edit baseline step only; nothing was published.

The new [member_profile_steps.exs](/workspace/memba/web/test/features/step_definitions/member_profile_steps.exs:1):

- Creates the Person through `PersonCommands.prepare_create/1` and `CommandDispatch.dispatch/2`.
- Uses strong consistency and a deterministic scenario-local email.
- Retains the Person identity and server-owned `expected_name` in scenario context.
- Adds no rename behavior or later step definitions.
- Leaves the feature text and tags unchanged.

Validation:

- Formatting: exit 0.
- Supporting suites: 16 tests, 0 failures.
- `bin/dev test:wip`: expected exit 2; exactly one scenario ran and advanced to the predicted next undefined step:
  `And Alice has since changed their name to "Alice Jones"`.

Full command results and log paths are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md:1). `dev check` was not run because the tagged scenario remains intentionally incomplete and the required acceptance observation reached the navigator’s predicted stopping point.