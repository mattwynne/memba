# Kaizen: move plan conformance into the implementation workflow

Date: 2026-05-29
Status: planned

## Context

The `iteration-review` workflow currently owns a `plan_conformance_gate`: an LLM
node that re-reads the iteration plan, enumerates every explicit requirement
("Add", "Implement", "Configure", "Run", "Use"...), and checks the
already-committed implementation against them, routing to `PLAN_CONFORMANT`,
`PLAN_REWORK`, or `HUMAN_INPUT` with its own snapshot→fix→verify repair loop.

This sits *after* implementation has finished, in a separate on-demand workflow,
in an isolated sandbox. It is the second time the plan is checked: the
implementation workflow drained a task list derived from the same plan, then
review re-derives the plan's requirements from scratch and grades the result.

Two problems fall out of that placement:

1. **Wrong owner.** Plan conformance is a *contract-with-the-spec* check. The
   implementation workflow has the plan as its explicit goal, holds the task
   list, and can iterate cheaply in its own loop. Discovering "you didn't build
   requirement X" only in a later review sandbox is the most expensive possible
   place to find it — after a full sandbox setup, dev check, and (in the current
   design) potentially three model reviews.

2. **It bloats review.** The gate and its repair scaffold are a large chunk of
   the review pipeline's complexity (see
   `2026-05-28-extract-iteration-review-workflow.md`), and they duplicate what
   the three independent reviewers are already told to check (`review.md`
   item 1, "Plan fidelity"). Review should be a code-polish + smell radar on
   *already-conforming* code, not a re-litigation of the spec.

The gate prompts are also overfit to a past incident: `plan_conformance_gate.md`
and `fix_plan_conformance.md` hardcode iteration-001 specifics ("Matt has
already confirmed the plan stands... plain Ecto CRUD spike instead of
Commanded/EventStore"). That is a one-off baked into a reusable gate — a smell
in its own right.

## Goal

Make `iteration-implementation` responsible for proving plan conformance before
it exits, so that `iteration-review` can *assume* conformance the same way it
assumes the suite is green.

## Proposed change

### In `iteration-implementation`

After the task loop and `dev check` are green, add a plan-conformance check as
the last gate before `final_artifact_gate`:

1. Collect the implementation evidence (diff since the iteration base, task
   list state, test output).
2. Run a plan-conformance gate that maps every explicit plan requirement to
   concrete code/config/migration/test evidence.
3. On a bounded, safe gap: route to a fix node that adds the missing
   deliverable + proving tests, then back through `dev check`.
4. On an unbounded/ambiguous gap, or a plan/architecture decision: stop for
   human input (do not exit "successfully").
5. Only reach `final_summary` once conformance holds.

Reuse the *cleaned* gate logic, not the iteration-001-specific text. Where it
needs the plan's requirements, derive them from the plan + the task list the
implementation loop already maintains, rather than re-reading the plan cold.

### In `iteration-review`

Remove the `plan_conformance_gate` and its repair scaffold entirely (covered by
the resolution plan in `2026-05-28-extract-iteration-review-workflow.md`). The
three reviewers keep a *light* plan-fidelity sanity check (`review.md` item 1)
as defence-in-depth, but review no longer carries a dedicated plan gate or
plan-repair loop.

## Acceptance criteria

- `iteration-implementation/workflow.fabro` proves plan conformance before
  `final_artifact_gate`, with a bounded fix loop and a human-input exit for
  unbounded/ambiguous gaps.
- The gate/fix prompts contain no iteration-001-specific text; requirements are
  derived from the plan + task list generically.
- `iteration-review` no longer contains a `plan_conformance_*` node, edge, or
  prompt.
- An implementation run that misses an explicit plan requirement does not exit
  as succeeded; it either repairs the gap or stops for human input.
- Both workflows validate with `fabro validate`.

## Risks / follow-ups

- The implementation workflow must agree with review on "what the iteration
  changes are" (the commit range since the iteration base). Use the same
  `base_sha` strategy adopted for review evidence (see the resolution plan in
  `2026-05-28-extract-iteration-review-workflow.md`).
- Moving conformance earlier means a badly off-plan implementation is caught
  before any review spend — the intended win — but the implementation loop must
  be careful not to enter an endless plan-repair cycle. Keep the existing
  bounded `max_visits` discipline and prefer human input on repeated gaps.
- Do not let the implementation-side gate weaken into "tests are green, ship it":
  passing dev check is necessary but not sufficient for plan conformance, as the
  current review gate already warns.
