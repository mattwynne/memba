Fresh review found one actionable domain defect despite the passing full gate: an unchanged historical name longer than 100 graphemes is rejected before the identical-target no-op comparison.

I replaced [change.md](/workspace/memba/.fabro/tmp/bdd/change.md) with one focused repair assignment:

- Add an aggregate regression proving a long historical name can be submitted unchanged without an event.
- Expect that new test to fail initially with `{:error, :name_too_long}`.
- Move length validation after normalized no-op detection while preserving validation for actual changes.
- Re-run the aggregate test file and the ordinary focused scenario.
- Keep the feature, iteration tag, stale-conflict behavior, and authorization unchanged.

{"preferred_next_label":"change"}