# Kaizen: nest validate→implement→review into one iteration-deliver workflow

Date: 2026-05-29
Status: implemented

> Builds on the trunk-based delivery model in
> `2026-05-29-deliver-iterations-by-merging-to-main.md` (implementation merges to
> `main`; review runs after, fix-forward, never blocks) and the split established in
> `2026-05-28-extract-iteration-review-workflow.md`. This kaizen adds an orchestration
> layer *above* those three workflows; it changes none of their internal behaviour.

## Context

Delivering one iteration is three separate manual steps today:

1. `iteration-planning` skill validates the plan via the `plan-validation` workflow.
2. `iteration-implementation` workflow implements it and squash-merges to `main`.
3. `iteration-review` workflow (via `bin/dev iteration-review`) reviews the merged
   diff post-hoc.

Each is kicked off by hand, one skill/command at a time. The phases are already
clean, durable, and independently runnable — but there is no "deliver this ready
iteration" button. Matt wants to kick off one thing and have the whole iteration get
done.

Fabro supports nesting workflows. **Child runs** in particular give each nested
workflow its own run ID, sandbox/clone, checkpoints, and outputs, with a durable
parent→child relationship (Children tab, listable, retryable). That is the right
primitive here: it lets us orchestrate the three existing workflows *unchanged*,
because each child keeps the managed-clone contract it depends on
(`.fabro/workflows/README.md`).

## Decision

Add an `iteration-deliver` workflow that orchestrates the three existing workflows as
**child runs**: validate → implement (land on `main`) → review the merged commit.
The `iteration-planning` skill kicks it off; it then runs unattended.

Decisions agreed with Matt (2026-05-29):

- **Merge-then-review ordering is preserved.** Review stays post-merge and
  non-blocking, exactly as in `2026-05-29-deliver-iterations-by-merging-to-main.md`.
- **Validation is deliver's first gate**, not a separate planning step. NOT READY
  stops deliver before anything is implemented.
- **Auto-continue.** A READY verdict flows straight into implementation and review
  with no human pause.
- **Mechanism: child-run orchestration.** Each phase runs as its own child run with
  its own sandbox, so the three workflows are reused as-is. (Sub-workflow `house`
  nodes / parse-time imports were rejected: they force the three clone/push/worktree
  contracts to share one clone and would require heavy refactoring of hardened
  graphs.)
- **Planning's responsibility ends at the validation boundary.** On NOT READY it
  re-interviews and re-runs deliver; on READY it hands off (reports the run URL) and
  stops while deliver continues unattended.

## Resulting flow

```
iteration-deliver (lightweight run: git read + fabro run-management tools; no memba-dev clone)

  orchestrate plan-validation child (-I plan_path)
        NOT READY ─▶ stop: validation:not-ready  (main untouched; nothing implemented)
        READY     ─▶ continue
  capture base_sha = origin/main tip            (pre-implementation tip → context)
  orchestrate iteration-implementation child (-I plan_path)
        fail      ─▶ stop: implementation failure (no review; iteration not on main)
        success   ─▶ "iteration NNN:" squash-commit now on main
  orchestrate iteration-review child (-I plan_path -I base_sha)
        (post-merge polish; non-blocking; never pushes red)
  finalize: bin/dev iteration-mark-merged-style ready→merged index update, push
  summary: stage-labeled report (child run IDs/URLs, validation verdict, review findings)
```

Each child's contract is unchanged:

| Child | Inputs deliver passes | Sandbox/clone | Effect |
|---|---|---|---|
| plan-validation | `plan_path` | own | READY / NOT READY verdict |
| iteration-implementation | `plan_path` | own (fresh clone of `main`) | squashed `iteration NNN:` pushed to `main` |
| iteration-review | `plan_path`, `base_sha` | own (fresh clone of merged `main`) | bounded polish commit + code-health findings |

`base_sha` is the only new plumbing: deliver captures `origin/main`'s pre-implementation
tip and threads it to the review child — exactly what `bin/dev iteration-review` does by
hand today (diff `base_sha..HEAD` of merged `main`).

## Design rules

1. **Children, not shared clone.** Deliver never sets `working_dir`, never disables
   `[run.clone]`, and never reaches into a child's clone. Each child clones and pushes
   on its own, preserving the managed-clone contract.

2. **Deliver runs light.** The deliver run itself needs only git read access (for
   `base_sha` and the finalize index update) and Fabro's run-management tools. The
   expensive `memba-dev` sandboxes live only in the children.

3. **Stage-labeled terminal status.** Deliver must expose *which stage* ended it, so
   callers can tell apart: `validation:not-ready` (with blocker text) vs
   implementation/workflow failure vs delivered-with-review-notes vs clean delivery.
   This is what lets the planning skill re-interview on a validation stop rather than
   triage a code failure.

4. **Failure semantics follow the trunk model.**
   - Validation NOT READY → stop at the gate; `main` untouched; planning re-interviews.
   - Implementation fails → stop; no review; iteration not on `main`; human triages.
   - Review "fails" → deliver still counts as **delivered** (implementation already
     merged; review is non-blocking by design). The summary surfaces the problem.

5. **One owner for the status transition.** Deliver's `finalize` step owns the
   `ready → merged` update to `docs/iterations/README.md` and the iteration folder,
   today split across the implementation (`ready-for-review`) and review
   (`iteration-mark-merged`) skills. `ready-for-review` survives only for manual,
   split-phase runs.

## Skill changes

- **`iteration-planning`**: terminal action changes from "submit to `plan-validation`"
  to "launch `iteration-deliver`." Its HARD-GATE is rewritten — planning still edits no
  application code, but it now *triggers* implementation via deliver. It launches
  deliver detached, captures the run ID, and **monitors only the validation stage**:
  NOT READY → summarize blockers, revise + commit + push, re-run deliver; READY →
  report the run URL and stop. (Trade-off: validate-only from planning goes away; run
  `plan-validation` by hand for that.)
- **New `iteration-deliver` skill**: a thin driver to kick off / re-run deliver against
  a selected `ready` iteration and report, for delivering a validated plan without
  going back through planning.
- **`iteration-implementation` / `iteration-review` skills**: retained as escape
  hatches for manual re-runs and resume scenarios; deliver becomes the normal path.

## Acceptance criteria

- A deliver run against a known-NOT-READY plan stops at the validation gate with a
  `validation:not-ready` status and blocker text; `main` is untouched.
- A deliver run against a `ready` plan produces, as nested child runs: plan-validation
  (READY), iteration-implementation (one `iteration NNN:` commit on `main`),
  iteration-review (runs post-merge against the captured `base_sha`); then a `merged`
  status in `docs/iterations/README.md` and a stage-labeled summary listing all child
  run IDs.
- Child runs are visible under the deliver run's Children tab.
- The planning skill, given a not-ready plan, loops to re-interview after deliver's
  validation stop; given a ready plan, it hands off and stops with the run URL.
- `fabro validate .fabro/workflows/iteration-deliver/workflow.toml` passes.

## Open items (verify before building out)

A throwaway deliver run that *only* validates and stops is a good first step to prove
1–4 before wiring implementation and review.

1. **Child-run auto-approval.** Parent-created children "may enter `pending` with
   `approval_required`" (`docs/tools/fabro/public/execution/child-runs.mdx`). Confirm
   the config/flag that lets deliver's children run without an operator checkpoint, so
   the run is truly unattended.
2. **Machine-readable validation verdict.** Confirm `plan-validation` exposes
   READY / NOT READY via a child outcome/output the orchestrator can gate on, and that
   it carries the blocker text planning needs. If it only emits prose, add a structured
   verdict (routing/output schema or `goal_gate`-style terminal status).
3. **Orchestrator footprint.** Confirm the orchestrator agent can capture `base_sha`
   and call the `fabro_*` run tools without a full `memba-dev` clone/env.
4. **In-run child invocation.** Confirm the supported mechanism for the orchestrator to
   start children with per-child `-I` inputs (agent `fabro_tools` MCP catalog:
   `fabro_run_create` → `fabro_run_gather` → `fabro_run_get`), and whether the graph
   gates are best expressed as one orchestrator agent node with internal gating or as
   several agent/script nodes with explicit `diamond` routing.

## Risks / follow-ups

- **Cost of failed validation cycles.** Each NOT-READY correction cycle now boots a
  deliver orchestrator + validation child rather than a bare validation run. Marginal
  (no implementation until READY); if it grates, add a fast standalone validation
  pre-check in planning with deliver re-validating as a cheap gate.
- **Auto-continue commits credits on READY.** A bad-but-READY plan burns implementation
  credits with no human stop — relevant given `2026-05-28-credit-exhaustion-mid-run.md`.
  Accepted per the auto-continue decision; a future `require_approval` input could
  reintroduce a pause without redesigning deliver.
- **Kaizen authorship stays human.** Deliver's stage-labeled summary should give a human
  enough to write a workflow-failure kaizen; the workflow does not author one.

## Resolution

Date: 2026-05-31

Root cause: Validate, implement, and review were separate operator steps, creating handoff friction and stale state risk.

Fix applied:

- `af1cd03`: added the nested iteration-deliver workflow.

Validation:

- Historical delivery evidence: the iteration-deliver workflow commit is present on `main`.

Remaining follow-up:

- Later notes track specific delivery-workflow hardening issues.
