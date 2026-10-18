Reviewed the full diff from the recorded base, relevant design/ADR guidance, handoff files, and actual test logs. The ordinary scenario and supporting tests are green; no implementation repair is needed.

I assigned one bounded clarity refactor in [.fabro/tmp/bdd/change.md](/workspace/memba/.fabro/tmp/bdd/change.md): rename the overly broad `@person_events` collection to reflect that it specifically drives both Person and email invalidations, while preserving the separate Person-only `PersonRenamed` path. The assignment retains the scenario identity, requires green starting checks, preserves the affected earlier examples, avoids duplicate selections and WIP machinery, and finishes with `bin/dev check`.

No product code was changed.

{"preferred_next_label":"change"}