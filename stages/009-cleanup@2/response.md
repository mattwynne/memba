Implemented and reviewed the agreed documentation-only cleanup without publishing.

- Updated [person_commands.ex](/workspace/memba/web/lib/memba/membership/person_commands.ex:1) to document both creation and self-service rename preparation responsibilities.
- Clarified that preparation does not dispatch commands and that authoritative validation, normalization, and rename decisions remain with the Person aggregate.
- No functions, tests, scenarios, command shapes, or behavior changed.

Verification:

- Assigned scenario before and after: `132 tests, 0 failures, 131 excluded`.
- `person_commands_test.exs` before and after: `7 tests, 0 failures`.
- Focused formatting completed successfully.
- `git diff --check`: passed.
- Full `dev check` was not rerun, as explicitly directed for this documentation-only cleanup.

The complete handoff and evidence paths are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md). No unresolved problems.