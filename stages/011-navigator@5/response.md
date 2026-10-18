The rejection assertion passed exactly as predicted, and the scenario now stops at the undefined projected-name assertion.

I updated [change.md](/workspace/memba/.fabro/tmp/bdd/change.md) with one projection-focused assignment:

- Project `PersonRenamed` into the existing Person read model.
- Preserve unrelated projected fields.
- Retain committed `ReadModelChanges` publication.
- Synchronize the winning rename deterministically.
- Define the current-name step using `PersonQueries.get_person/1`.
- Add focused projection and stale-no-write coverage.

The predicted next failure is the explicit confirmation step:

`When Alice confirms replacing "Alice Jones" with "Alice Brown"`

Live-query invalidation, UI behavior, and confirmation remain out of scope for this change.

{"preferred_next_label":"change"}