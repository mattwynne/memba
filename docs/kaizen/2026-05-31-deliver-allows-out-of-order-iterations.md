# Problem: deliver allows iterations to start out of order

Date: 2026-05-31

## Context

We were preparing to deliver `docs/iterations/010-shared-magic-link-auth/plan.md` after it had been validated. Iteration 010 assumes the route/admin surface split from `docs/iterations/009-routing-and-liveview-surface-split/plan.md` already exists.

The command path was:

```text
bin/dev fabro deliver docs/iterations/010-shared-magic-link-auth/plan.md
```

The delivery helper marked iteration 010 as `implementing` and started Fabro implementation run `01KSZC62M7H741DK0T18PM1JNF`.

## Expected standard

Iterations are numbered and sequenced so later slices can rely on earlier slices being delivered. Starting implementation should protect that sequencing, not just the single implementation WIP slot.

A later iteration should not start implementation while an earlier iteration is still only `validated`, unless the workflow has an explicit way to declare and approve that the iterations are independent or intentionally reordered.

## What happened

Iteration 010 was allowed to start while iteration 009 was still `validated`, not `merged`.

The 010 implementation run then discovered the missing prerequisite itself. Its generated `docs/iterations/010-shared-magic-link-auth/route-inspection.md` recorded:

- there was no `/admin` scope,
- no `:staff_browser` pipeline,
- no `MembaWeb.Admin.*` LiveView namespace,
- and the current harness routes were still exposed at public paths.

That meant 010 had begun absorbing prerequisite 009 work instead of building on a completed 009 foundation.

We interrupted and removed the 010 run, restored 010 to `validated`, and then started delivery for 009 first:

```text
fabro rm --force 01KSZC62M7H7
bin/dev iteration mark docs/iterations/010-shared-magic-link-auth/plan.md validated
bin/dev fabro deliver docs/iterations/009-routing-and-liveview-surface-split/plan.md
```

Relevant commits:

- `cdeaf6a` — `iteration 010: mark implementing`
- `6098636` — `iteration 010: restore validated before 009 delivery`
- `298f874` — `iteration 009: mark implementing`

## Impact

This wasted implementation effort and created sequencing confusion. If it had continued, iteration 010 could have published a mixed implementation containing both route-split work and magic-link auth work, making review harder and weakening the iteration boundary.

It also risked hiding the real cause: the code was not wrong because 010's implementation was intrinsically bad; it was wrong because the prerequisite iteration had not been delivered.

## What allowed it to happen

`bin/dev fabro deliver` checks only that:

- the selected plan is `ready` or `validated`, and
- the implementation WIP slot is clear of active statuses such as `implementing`, `ready-for-review`, `reviewing`, or `finalizing`.

It does not check whether earlier-numbered iterations are already `merged` before allowing a later-numbered iteration to reserve the WIP slot.

Plan validation can run ahead of implementation by design, but the same lifecycle model does not distinguish "validated and ready to deliver now" from "validated but waiting for an earlier dependency to merge".

## Observations

- `docs/iterations/README.md` showed iteration 009 as `validated` and iteration 010 as `validated` before 010 delivery began.
- The WIP slot was technically clear because no iteration was active, so the delivery helper allowed 010 to start.
- Iteration 010's own plan text depended on the post-009 route structure: it refers to protecting `/admin/*` and assumes the admin route/module split exists.
- The abnormality became visible only after implementation had started and inspected the codebase.
- Recovery required operator judgement: identify the prerequisite gap, stop the 010 run, restore 010 status, and manually start 009.

## Why this matters

Iteration boundaries are meant to keep each slice independently reviewable and shippable. If later slices can start before earlier dependent slices are merged, the workflow can accidentally create large mixed-scope changes and make automated review, rollback, and learning less reliable.

## Open questions

- Should numbered iterations be strictly delivered in order by default?
- If out-of-order delivery is sometimes valid, where should an explicit dependency or independence declaration live?
- Should `validated` be split into separate states for "validated but blocked by predecessor" and "validated and deliverable now"?

## Possible prevention ideas

- Add a delivery preflight that refuses to start iteration N when any lower-numbered iteration is not `merged`, unless an explicit override/dependency declaration allows it.
- Teach plan validation or iteration planning to record dependencies between iterations when a plan assumes another slice's output.
- Make the refusal message name the earlier blocking iteration and show the command to deliver it first.

## Resolution

Date: 2026-05-31

Root cause: the delivery lifecycle guarded only the selected plan status and the active implementation WIP slot. It allowed any `ready` or `validated` iteration to reserve implementation when no active iteration was present, even if earlier-numbered iterations were still unmerged prerequisites.

Fix applied:

- `.fabro/workflows/scripts/iteration_status.py`: added `check-predecessors`, which fails when any earlier-numbered iteration in `docs/iterations/README.md` is not `merged` and prints the blocking iteration paths.
- `bin/dev`: exposed `bin/dev iteration check-predecessors`, pulls `origin/main` before delivery status checks, and runs the predecessor check before waiting for/reserving the implementation WIP slot.
- `.fabro/workflows/iteration-implementation/workflow.fabro`: added the same predecessor check to the direct implementation WIP gate so manual implementation runs cannot bypass ordered delivery.
- `.fabro/workflows/README.md`: documented ordered single-piece-flow and updated the manual implementation escape-hatch commands.

Validation:

- `python3 -m py_compile .fabro/workflows/scripts/iteration_status.py` — passed.
- `bash -n bin/dev` — passed.
- `MEMBA_DEVENV_SHELL=1 ./bin/dev iteration check-predecessors docs/iterations/009-routing-and-liveview-surface-split/plan.md` — passed while 001–008 were merged.
- `MEMBA_DEVENV_SHELL=1 ./bin/dev iteration check-predecessors docs/iterations/010-shared-magic-link-auth/plan.md` — failed as expected while 009 was `implementing`, naming 009 as the blocker.
- `fabro validate .fabro/workflows/iteration-implementation/workflow.fabro` — passed with existing goal-gate warnings.
- `PATH="$PWD/bin:$PATH" dev check` — passed, 132 tests, 0 failures.

Remaining follow-up:

- If out-of-order delivery becomes necessary, add an explicit dependency/override mechanism rather than weakening the default ordered guard.
