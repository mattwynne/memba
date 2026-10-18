Implemented the assigned trust-boundary repair without publishing.

- `PersonCommands.prepare_rename/4` now receives the server-held expected name separately from editable attributes.
- Actor validation and self-target authorization still happen before reading editable input.
- Updated dispatch and acceptance callers to use the edit baseline or captured conflict value directly.
- Added regression coverage proving an injected posted `expected_name` cannot replace the server-held baseline.
- Preserved the agreed scenario and feature file unchanged.

Validation:

- Format check: passed. A writing formatter attempt was blocked by root-owned sandbox files; the non-writing check passed after applying its reported formatting.
- Focused preparation/dispatch tests: 11 tests, 0 failures.
- Final focused acceptance: 132 generated, 131 excluded, exactly the assigned scenario ran, 0 failures.
- `dev test:wip` was not run because the scenario is untagged.
- The full `dev check` was left for the workflow’s later exact-state gate, as assigned.
- Nothing was published.

Full evidence and log paths are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md).