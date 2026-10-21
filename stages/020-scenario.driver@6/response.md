Updated the two possessive historical-author bindings in [member_profile_steps.exs](/workspace/memba/web/test/features/step_definitions/member_profile_steps.exs:60) to anchored regular expressions. Binding bodies, scenarios, and tags remain unchanged.

Validation:

- Formatter: exit 0
- Cucumber configuration: 2 tests, 0 failures
- `bin/dev test:wip`: exactly 1 scenario, 0 failures
- WIP wrapper exited 1 as designed and requested `@wip` removal

Evidence is recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md). The navigator retains responsibility for removing `@wip`; no full `bin/dev check` or publishing was performed.