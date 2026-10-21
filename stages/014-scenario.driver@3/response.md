Implemented the two historical contribution fixtures in [messaging_steps.exs](/workspace/memba/web/test/features/step_definitions/messaging_steps.exs:69):

- Creates Alice’s Kootenay root conversation through the existing command/projector helper.
- Creates the Rockies root conversation and posts Alice’s deterministic reply.
- Preserves existing message/reply context structures and delivery cleanup conventions.

Validation:

- Focused formatting check passed.
- `bin/dev test:wip` selected exactly one scenario and exited 2 with one expected failure at the next undefined step: `When Alice changes their name to "Alice Jones"`.
- The `@wip` tag remains unchanged.
- Full `bin/dev check` was intentionally left for the workflow check stage.

Detailed evidence is recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md), with acceptance output in [driver-historical-contributions-wip.log](/workspace/memba/.fabro/tmp/bdd/driver-historical-contributions-wip.log).