The conditional rename implementation matched its prediction: 36 focused Person tests and 3 router tests passed, and the scenario now stops at the undefined stale-submission step.

I updated [change.md](/workspace/memba/.fabro/tmp/bdd/change.md) with one assignment: submit Alice’s preserved Smith-baseline edit to Brown through the production rename path, retain the exact authoritative conflict result, and add a focused Commanded dispatch test for that sequence.

The predicted next failure is:

`Then the change should be rejected because their name changed elsewhere`

Projection, assertions, confirmation, UI coordination, and readback remain out of scope for this change.

{"preferred_next_label":"change"}