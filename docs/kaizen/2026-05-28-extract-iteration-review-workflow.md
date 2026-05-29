# Idea: extract review/repair tail into a separate iteration-review workflow

Date: 2026-05-28
Status: phase 1 (extraction) shipped; phase 2 (simplification) planned 2026-05-29

> **2026-05-29 update.** Phase 1 — extracting the review tail into its own
> `iteration-review` workflow — is done. Running it against iterations 001/002
> exposed a second problem: the extracted pipeline is *itself* both ineffective
> and over-complex. It runs three overlapping quality gates, triplicates the
> snapshot→fix→verify repair scaffold, fights Fabro's git mechanics in ~70 lines
> of defensive bash, auto-merges silently on success while discarding every
> non-blocking smell finding, and carries iteration-001-specific text baked into
> supposedly reusable prompts. The "## Resolution plan" section below records the
> agreed simplification. Moving plan conformance out of review (into the
> implementation workflow) is tracked separately in
> `2026-05-29-move-plan-conformance-to-implementation.md`.

## Context

The current `iteration-implementation` workflow is responsible for both
implementing an iteration plan and then exhaustively reviewing the result. The
review/repair tail includes:

- `plan_conformance_gate` + `snapshot_before_plan_repair` + `fix_plan_conformance` + `verify_plan_repair` + `plan_not_ready`
- `adr_coherence_gate` + `snapshot_before_adr_repair` + `fix_adr_coherence` + `verify_adr_repair` + `adr_not_ready`
- `review_fork` running `claude_review`, `codex_review`, and `gemini_review` in parallel
- `review_merge` + `synthesize_review` + `review_gate`
- `snapshot_before_review_repair` + `apply_review_fixes` + `verify_review_repair` + `not_ready`
- `final_artifact_gate` + `final_summary`

On the runs we have observed, the workflow has never reached these nodes — it
fails or times out inside the per-task implementation loop or at `dev_check`.
The review/repair machinery is dead weight on every failed run: it adds nodes
to reason about, prompts to maintain, model-stylesheet entries to keep in
sync, and surface area for regressions when we tweak the implementation loop.

It also conflates two very different jobs:

1. **Implementation** — drain the task list, keep `dev check` green, leave a
   clean working tree with per-task commits.
2. **Review** — independently judge whether the resulting commits conform to
   the plan and ADRs, and whether multiple reviewers accept the implementation.

These are independently useful. We frequently want to re-run review against an
existing implementation without re-running the implementation loop, and we
want to iterate on the implementation loop without paying the cost of
review-loop maintenance.

## Goal

Reduce `iteration-implementation` to just the implementation job, and move the
review/repair tail into a separate `iteration-review` workflow that can be run
on demand against an iteration whose implementation workflow has already
exited cleanly.

## Proposed split

### `iteration-implementation` (trimmed)

Ends as soon as the implementation is internally consistent and `dev check`
passes against a clean working tree.

Nodes retained:

- `read_plan` / `read_failed`
- `preflight_sandbox` / `preflight_failed`
- `sync_task_list`
- `all_tasks_done` (check_task_list)
- `implement_next_task`
- `validate_task` + `task_gate`
- `reset_task_attempt`
- `commit_task`
- `task_not_ready`
- `dev_check`
- `fix_dev_check`
- `final_artifact_gate`
- `final_summary`

Edges:

- `dev_check -> final_artifact_gate` on success
- `dev_check -> fix_dev_check -> dev_check` on failure (existing `max_visits=3`)
- `final_artifact_gate -> final_summary -> exit`

Nodes removed (move to `iteration-review`):

- `plan_conformance_gate`, `plan_gate`, `snapshot_before_plan_repair`,
  `fix_plan_conformance`, `verify_plan_repair`, `plan_not_ready`
- `adr_coherence_gate`, `adr_gate`, `snapshot_before_adr_repair`,
  `fix_adr_coherence`, `verify_adr_repair`, `adr_not_ready`
- `review_fork`, `claude_review`, `codex_review`, `gemini_review`
- `review_merge`, `synthesize_review`, `review_gate`
- `snapshot_before_review_repair`, `apply_review_fixes`,
  `verify_review_repair`, `not_ready`

Corresponding model-stylesheet entries for the removed nodes should be deleted
from the trimmed workflow.

### `iteration-review` (new workflow)

Inputs:

- `plan_path` (same shape as `iteration-implementation`)
- Optionally a base ref to diff against (default: the merge base with `main`).

Preconditions checked up front:

- `plan.md` exists and is readable.
- Working tree is clean.
- `dev check` passes (re-run as the first gate; fail fast if it doesn't).

Pipeline (sequential, no per-task loop):

1. `preflight_sandbox`
2. `dev_check`
3. `plan_conformance_gate` (+ snapshot/fix/verify repair loop, `max_visits=2`)
4. `adr_coherence_gate` (+ snapshot/fix/verify repair loop, `max_visits=2`)
5. `review_fork` → `claude_review`, `codex_review`, `gemini_review`
6. `review_merge` → `synthesize_review` → `review_gate`
7. On `Fix`: `snapshot_before_review_repair` → `apply_review_fixes` → `verify_review_repair` → back to `dev_check`
8. On accepted: `final_artifact_gate` → `final_summary` → exit
9. On `Needs human input` at any gate: route to the corresponding `*_not_ready` exit node

The repair branches loop back through `dev_check` so that any fix that breaks
the build is caught immediately, exactly as today.

The review workflow re-uses the existing prompts under
`.fabro/workflows/iteration-implementation/prompts/` for now; later they can
be moved into the new workflow's directory.

## Migration steps

1. Copy `.fabro/workflows/iteration-implementation/` to
   `.fabro/workflows/iteration-review/` and trim it down to the review-only
   pipeline above. Keep its `prompts/` directory in sync with the prompts it
   actually uses, copying from the implementation workflow as needed.
2. Edit `.fabro/workflows/iteration-implementation/workflow.fabro` to remove
   all review/repair/ADR/plan-conformance nodes and edges, and prune the
   model-stylesheet entries that no longer apply.
3. Validate both workflows with `fabro validate ...`.
4. Update any docs or commands that currently expect `iteration-implementation`
   to also run review (e.g. the kaizen entries in `docs/kaizen/`).
5. Add a short `README.md` (or extend an existing one) describing the two-step
   flow: run `iteration-implementation`, then optionally run
   `iteration-review` against the same plan.

## Acceptance criteria

- `iteration-implementation/workflow.fabro` no longer references any review,
  plan-conformance, or ADR-coherence node.
- The implementation workflow ends at `final_summary` immediately after
  `dev_check` is green and `final_artifact_gate` passes.
- A new `iteration-review/workflow.fabro` exists and runs the previously
  embedded gates against a clean implementation commit set.
- Both workflows validate with `fabro validate`.
- Re-running review against an already-clean implementation does not require
  rerunning any implementation nodes.
- Docs describe the new two-step flow.

## Risks / follow-ups

- The review workflow needs to agree with the implementation workflow on what
  "the iteration changes" are. Today the gates look at the working tree;
  after the split they will look at the commit range since the iteration's
  base. The base-detection logic from `final_artifact_gate` is a good starting
  point.
- Some prompts may currently assume context built up during implementation
  (e.g. todo-list state). Those should be adjusted to read from `todo.md` and
  the commit log instead of in-memory context.
- We should decide whether `iteration-review` can mutate the working tree at
  all (currently the `fix_*` nodes do). Keeping that behaviour is fine for now;
  later we may want a read-only review mode.

---

## Resolution plan (2026-05-29): simplify the extracted pipeline

The extraction (phase 1) left the review workflow doing too much. This phase
keeps its **autonomous** behaviour — auto-fix bounded issues, auto-PR, squash
auto-merge — but cuts the redundancy, fixes the plumbing that caused most of
the operational kaizen trail, and makes emerging code smells visible instead of
silently discarded.

### Decisions (agreed with Matt, 2026-05-29)

- **Keep it autonomous.** Most of the time it should clean up the code and merge
  with no human involvement. Alerts are only for *judgement-worthy* findings a
  human might need to weigh in on — not a dump of every nitpick.
- **Keep the three-model reviewer panel** (Claude + Codex/GPT + Gemini) plus
  synthesis. The cross-model diversity is the point and is worth the cost.
- **Plan conformance leaves review** and becomes the implementation workflow's
  job (tracked in `2026-05-29-move-plan-conformance-to-implementation.md`).
  Review assumes plan conformance, the way it assumes the suite is green.
- **ADR coherence stays in review** as an independent reviewer concern, not a
  standalone gate.

### New purpose framing

The pipeline stops being a "did you build the right thing" gate and becomes a
**code-polish + smell-radar that runs on already-conforming code**. That is the
job Matt actually wants from it.

### Change 1 — collapse three gates into one review stage

Delete the two standalone gates and their repair scaffolds (≈12 nodes,
4 prompts):

- `plan_conformance_gate`, `plan_gate`, `snapshot_before_plan_repair`,
  `fix_plan_conformance`, `verify_plan_repair`, `plan_not_ready`
- `adr_coherence_gate`, `adr_gate`, `snapshot_before_adr_repair`,
  `fix_adr_coherence`, `verify_adr_repair`, `adr_not_ready`
- prompts `plan_conformance_gate.md`, `adr_coherence_gate.md`,
  `fix_plan_conformance.md`, `fix_adr_coherence.md`
- the matching model-stylesheet entries

Resulting flow:

```
read plan → preflight → dev check (+fix loop) → collect evidence
   → [claude | codex | gemini] review (parallel) → synthesize → route:
        ACCEPTED      → (silent auto-fix if any) → code-health note (only if judgement findings) → PR + squash-merge
        FIX           → snapshot → apply fixes → verify → dev check → re-synthesize   (single repair loop, max_visits budget)
        HUMAN_INPUT   → stop  (ADR violation, behavioural gap, repeated blocker, anything needing human judgement)
```

ADR conformance becomes a required section in `review.md` (already item 0) and
`synthesize_review.md`; ADR violations route to `HUMAN_INPUT`. One repair
scaffold instead of three.

### Change 2 — the code-health alert channel

Add a node after synthesis (`record_code_health`) that appends to a tracked
`docs/code-health.md` **only when synthesis surfaces judgement-worthy
non-blocking findings** — never a "no findings" entry, to keep the log
high-signal. Each entry records date, iteration/plan, file(s), the smell, why it
might need human judgement, and that it was merged anyway. The note rides the
squash-merge into `main`, so it is git-visible and accrues a trend Matt reads on
his own terms. Bounded safe fixes are still applied silently and produce no
entry.

### Change 3 — deterministic plumbing (closes the evidence/clone kaizens)

The `base_ref` (default `origin/main`) is currently re-resolved *inside* the
sandbox via merge-base/fetch-deepen archaeology — the root of the
evidence-collection silent-exit, shallow-clone, and run-branch-ancestry
kaizens. Replace with a base **SHA** resolved locally where full history exists:

- implementation handoff (`implementation.md`) records `Base sha:` (the commit
  the run branched from), not just `Base ref:`;
- `bin/dev iteration-review` resolves that SHA locally and passes `base_sha`;
- `collect_implementation_evidence` collapses from ~70 lines to a deterministic
  `git diff base_sha..HEAD`, with a single `--unshallow` fallback and a loud,
  non-silent failure.

This delivers the base-SHA / run-metadata diff strategy left open in
`2026-05-29-iteration-review-evidence-script-silent-exit.md` ("Current
takeaway").

### Change 4 — prompt cleanup

Strip the iteration-001-specific text ("Matt has already confirmed... plain
Ecto CRUD spike instead of Commanded/EventStore") out of the surviving prompts.
Give the reviewer/synthesis prompts an explicit ADR section and the code-health
classification rule: blocking → `HUMAN_INPUT`; bounded-safe → silent fix;
judgement-worthy non-blocking → code-health note + merge.

### Acceptance criteria

- `iteration-review/workflow.fabro` has no `plan_conformance_*` or
  `adr_coherence_*` nodes/edges; the four corresponding prompts are deleted; the
  model-stylesheet has no orphaned entries.
- Exactly one snapshot→fix→verify repair scaffold remains (the review repair
  loop).
- `collect_implementation_evidence` takes `base_sha` and diffs
  `base_sha..HEAD` with no merge-base archaeology; any failure prints
  diagnostics (never a silent exit).
- `bin/dev iteration-review` passes `base_sha`; `implementation.md` records it.
- A review that finds only judgement-worthy non-blocking smells auto-merges and
  appends one entry to `docs/code-health.md`; a clean review writes no entry.
- No surviving prompt references iteration-001 specifics.
- `fabro validate .fabro/workflows/iteration-review/workflow.toml` passes.

### Out of scope

- Moving plan conformance into `iteration-implementation`
  (`2026-05-29-move-plan-conformance-to-implementation.md`).
- Any change to the three-model panel composition (explicitly retained).
