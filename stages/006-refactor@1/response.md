Assigned one focused cleanup in [.fabro/tmp/bdd/change.md](/workspace/memba/.fabro/tmp/bdd/change.md): separate the rename target identity from editable `name` and `expected_name` attributes at the trusted command-preparation boundary.

The assignment preserves:

- The exact now-untagged stale-edit scenario and its ordinary focused command.
- Authorization before command construction, including malformed, mismatched, no-op, and confirmation attempts.
- Aggregate-owned normalization and conditional comparison.
- Existing command, event, projection, publication, and historical replay behavior.
- Non-duplicated focused unit coverage.

The prior driver’s actual logs show the implementation and focused tests green; the WIP command’s nonzero status was solely its green-result guard. No product code was changed or published, and the full gate is deliberately reserved until the cleanup returns and the complete diff is reconsidered.

{"preferred_next_label":"change"}