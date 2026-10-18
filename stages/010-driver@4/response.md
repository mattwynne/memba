Implemented the assigned stale-rename rejection assertion in [member_profile_steps.exs](/workspace/memba/web/test/features/step_definitions/member_profile_steps.exs:94).

The step now verifies:

- The exact retained result is `{:error, {:name_changed, authoritative_current_name}}`.
- The separately retained authoritative name matches and is nonblank.
- The original baseline and raw draft remain available.
- The assertion uses the sole stored edit and is person-agnostic.
- No command is redispatched and context remains unchanged.

Validation:

- Formatting: exit 0.
- Focused dispatch suite: 5 tests, 0 failures.
- `bin/dev test:wip`: exactly 1 scenario executed and stopped at the predicted next undefined step, `And Alice should be known as "Alice Jones"`; expected exit 2.
- Independent read-only review: no findings.
- `dev check` was intentionally not rerun, per the assignment.

Full evidence and log paths are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md). Nothing was committed or published.