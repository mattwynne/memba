Implemented the single conditional-confirmation scenario step in [member_profile_steps.exs](/workspace/memba/web/test/features/step_definitions/member_profile_steps.exs:116).

The confirmation:

- Uses the trusted Person identity and retained scenario edit state.
- Verifies the displayed current name and replacement against the frozen conflict values.
- Issues a new conditional `RenamePerson` attempt—no force-write.
- Waits for deterministic Person projection consistency.
- Preserves the original stale-conflict evidence while recording the confirmation result.

Validation completed:

- Focused supporting suites: 12 tests, 0 failures.
- `bin/dev check`: passed—19 package tests, 1,839 app tests, and 7 browser scenarios.
- `bin/dev test:wip`: 1 test, 0 failures; wrapper exited 1 as expected with `This scenario now passes. Remove its @wip tag.`
- Diff and independent review: no findings.
- Feature wording and tags remain unchanged.

Full evidence is recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md). The source change is staged; nothing was committed or published.