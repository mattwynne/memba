The live-query repair is complete and matches the review requirement:

- The expected regression test failed with `:unsupported_projector_event`.
- The repaired adapter suite passes all 46 tests.
- The ordinary focused scenario still passes.
- The committed change invalidates only `{:person, person_id}` for a rename.

I replaced [change.md](/workspace/memba/.fabro/tmp/bdd/change.md) with the remaining single repair: preserve the eventless no-op when an unchanged historical name exceeds the newer 100-grapheme rename limit. The current aggregate suite passes 25 tests because that boundary case is absent; the assignment specifies the expected red assertion, retained overlength-change rejection, supporting suites, and focused acceptance command.

{"preferred_next_label":"change"}