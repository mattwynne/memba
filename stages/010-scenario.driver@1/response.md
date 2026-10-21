Implemented the selected setup change only.

- Added the exact `Alice is a member of Rockies Cycling Co-op` binding in [authentication_steps.exs](/workspace/memba/web/test/features/step_definitions/authentication_steps.exs:28), reusing `ensure_member/3`.
- Preserved the scenario and `@wip` tag unchanged.
- Formatted the changed file successfully.
- `bin/dev test:wip` executed exactly one scenario and exited 2 at the predicted next undefined step: `Alice is known as "Alice Smith"`.
- Recorded command results and log paths in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md).
- Did not run the full `bin/dev check`, commit, or publish.