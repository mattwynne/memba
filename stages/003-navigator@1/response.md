The WIP baseline matched the prediction: exactly one scenario ran and failed at the undefined first Given, with `1 test, 1 failure` and exit status `2`.

Evidence is preserved in:

- [wip-initial.log](/workspace/memba/.fabro/tmp/bdd/wip-initial.log)
- [wip-initial.status](/workspace/memba/.fabro/tmp/bdd/wip-initial.status)
- [change.md](/workspace/memba/.fabro/tmp/bdd/change.md)

The assignment covers one coherent change: implement the conditional self-rename Membership slice—command, authorization-aware preparation, aggregate conflict semantics, event, projection, exact live-query invalidation, real scenario steps, and focused supporting tests. The next predicted acceptance result is `1 test, 0 failures`; `test:wip` should then exit `1` only to request removal of `@wip`.

The plan’s later consolidated feature layout differs from this checkout, but the checked-in evaluation case documents that historical fixture intentionally. Selection is correct, so it is not a blocker.

{"preferred_next_label":"change"}