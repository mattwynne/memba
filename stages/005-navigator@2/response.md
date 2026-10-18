The previous change behaved exactly as predicted: all 16 supporting tests passed, and the selected scenario advanced to the undefined intervening-rename step.

I updated [change.md](/workspace/memba/.fabro/tmp/bdd/change.md) with one next assignment: implement the conditional Person rename write path—command, event, trusted self-only preparation, aggregate normalization/concurrency rules, routing/dispatch, focused tests—and define only:

`Alice has since changed their name to "Alice Jones"`

Projection, UI behavior, and later scenario steps remain explicitly out of scope. The predicted next failure is the undefined stale-submission step:

`When Alice submits the older change to "Alice Brown"`

{"preferred_next_label":"change"}