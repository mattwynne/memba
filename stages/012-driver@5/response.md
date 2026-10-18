Implemented the assigned Person projection/read slice without publishing or changing the agreed feature.

Key changes:

- [person.ex](/workspace/memba/web/lib/memba/membership/projectors/person.ex:34) now projects `PersonRenamed`, updating only `name` and `updated_at`.
- [member_profile_steps.exs](/workspace/memba/web/test/features/step_definitions/member_profile_steps.exs:33) uses strong consistency for the winning rename and reads the projected name through `PersonQueries.get_person/1`.
- [person_projection_test.exs](/workspace/memba/web/test/memba/membership/person_projection_test.exs:103) covers normalized readback, unchanged unrelated fields/email rows, committed publication, and preservation of Jones after the stale Brown attempt.

Validation:

- Focused red test: 7 tests, expected 1 failure because the projection remained “Alice Smith.”
- Focused green test: 7 tests, 0 failures.
- Required combined supporting command: 12 tests, 0 failures.
- `bin/dev test:wip`: exactly one scenario executed and stopped at the predicted next undefined step:
  `When Alice confirms replacing "Alice Jones" with "Alice Brown"`.
- `git diff --check` passed.
- Independent read-only review found no issues.
- `dev check` was intentionally not run while the next scenario step remains undefined.

Full command results and log paths are recorded in [result.md](/workspace/memba/.fabro/tmp/bdd/result.md). Nothing was committed or published.