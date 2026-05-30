# Problem: plan-validation parallel fan-in does not expose reviewer evidence to synthesis

Date: 2026-05-30

## Context

We hardened the plan-validation workflow after a false READY result where independent reviewers found blocking gaps but the synthesis stage did not see or account for those findings.

The safe working workflow now validates plans sequentially:

```text
read_plan -> gemini_review -> claude_review -> codex_review -> synthesize
```

This is slower than intended, but it keeps all reviewer decisions and blocking-gap summaries visible to synthesis through ordinary context keys.

The workflow has eval coverage:

```bash
.fabro/workflows/plan-validation/test.sh
```

The eval runs the real workflow against two fixtures:

- `.fabro/workflows/plan-validation/test/fixtures/unanimous-pass/plan.md`
- `.fabro/workflows/plan-validation/test/fixtures/definite-fail/plan.md`

Expected results:

- unanimous-pass -> workflow succeeds / READY
- definite-fail -> workflow fails / NOT READY

## What we tried

We tried to restore the documented Fabro fan-out/fan-in pattern:

```text
read_plan -> review_fork
review_fork -> gemini_review
review_fork -> claude_review
review_fork -> codex_review
gemini_review -> review_merge
claude_review -> review_merge
codex_review -> review_merge
review_merge -> synthesize
```

Fabro docs/examples say merged branch results should be available to downstream nodes through `parallel_results.json`.

Relevant docs read:

- Local: `docs/tools/fabro/public/tutorials/parallel-review.mdx`
- Local: `docs/tools/fabro/public/tutorials/ensemble.mdx`
- Local: `docs/tools/fabro/public/workflows/stages-and-nodes.mdx`
- Local: `docs/tools/fabro/public/execution/context.mdx`
- Local: `docs/tools/fabro/public/agents/outputs.mdx`
- Local: `docs/tools/fabro/public/examples/clone-substack.mdx`

Public docs links:

- https://docs.fabro.dev/tutorials/parallel-review
- https://docs.fabro.dev/tutorials/ensemble
- https://docs.fabro.dev/workflows/stages-and-nodes
- https://docs.fabro.dev/execution/context
- https://docs.fabro.dev/agents/outputs
- https://docs.fabro.dev/examples/clone-substack

GitHub issue/PR searches checked:

- https://github.com/fabro-sh/fabro/issues?q=parallel_results.json
- https://github.com/fabro-sh/fabro/issues?q=fan_in
- https://github.com/fabro-sh/fabro/issues?q=parallel.fan_in
- https://github.com/fabro-sh/fabro/issues?q=parallel+merge+preamble

No obvious existing issue matched this exact `parallel_results.json` / reviewer-evidence visibility problem.

The most relevant doc statement is in `workflows/stages-and-nodes.mdx`:

```text
The merged results are available to downstream nodes as parallel_results.json.
```

The clone-substack example repeatedly instructs downstream synthesis nodes to:

```text
Read branch outputs via parallel_results.json. If parallel_results.json is missing, fall back to reading .workflow/... files.
```

## Failed attempts

### 1. Plain fan-out/fan-in with prompt synthesis

Commit attempted:

```text
492a7a8 Restore parallel plan validation fan-in
```

Result: eval failed. The synthesis preamble after merge showed only branch metadata:

```text
parallel.branch_count
parallel.fan_in.best_head_sha
parallel.fan_in.best_id
parallel.fan_in.best_outcome
parallel.results
```

It did not include reviewer response bodies or reviewer context fields.

The attempt was reverted:

```text
a45cfff Revert "Restore parallel plan validation fan-in"
```

### 2. Reviewer-written files collected after fan-in

Commit attempted:

```text
59bab04 Collect parallel plan validation reviews
```

The idea was for each reviewer branch to write a review artifact, then collect those files after merge.

Result: eval failed. The collect step could not find the files after fan-in:

```text
Missing review artifact: .fabro/workflows/plan-validation/review-output/gemini.md
Missing review artifact: .fabro/workflows/plan-validation/review-output/claude.md
Missing review artifact: .fabro/workflows/plan-validation/review-output/codex.md
Plan validation failed: not all parallel reviewer artifacts were collected after fan-in.
```

This suggests branch working-tree file writes are not a reliable way to pass all parallel outputs to the merged path, at least in this workflow/server version.

The attempt was reverted:

```text
f00c353 Revert "Collect parallel plan validation reviews"
```

### 3. Parallel fan-in with prompt instructed to read `parallel_results.json`

Commit attempted:

```text
c171a3e Try parallel plan validation fan-in
```

Result: eval failed. The synthesis prompt still saw only `parallel.results` metadata and did not see reviewer bodies or context fields. The pass fixture routed to NOT READY because the required reviewer evidence was missing.

The attempt was reverted:

```text
229808a Revert "Try parallel plan validation fan-in"
```

### 4. Parallel fan-in with agent synthesis (`shape=box`)

Commit attempted:

```text
c818e07 Use agent synthesis for parallel plan validation
```

The idea was that a full agent node could use tools to find/read `parallel_results.json`, whereas a prompt node cannot.

First eval attempt hit transient Docker infrastructure:

```text
run: 01KSVZ60PJ68TQG1K8TRK3FWYJ
failure: Failed to initialize sandbox / Failed to create Docker container / Timeout error
```

A retry ran the workflow but still failed the pass fixture:

```text
run: 01KSVZEDYPFB4T66ENX77CNYBT
```

The synthesis agent reported:

```text
Validation cannot be marked READY because the required merged reviewer evidence is incomplete/not visible.

I searched for parallel_results.json under the repository and .fabro/, including run scratch paths for 01KSVZEDYPFB4T66ENX77CNYBT. The file was not present, and I could not see the required reviewer routing context fields for Gemini, Claude, and Codex/GPT.
```

This attempt was reverted:

```text
4405875 Revert "Use agent synthesis for parallel plan validation"
```

## Current working state

The workflow is back to the safe sequential reviewer chain. It is slower but correct.

Latest successful eval after reverting the agent-synthesis attempt:

```text
.fabro/workflows/plan-validation/test.sh
```

Results:

```text
PASS: unanimous-pass produced READY/success
PASS: definite-fail produced NOT READY/failure
plan-validation eval suite: OK
```

Run IDs:

```text
unanimous-pass: 01KSVZN8T2D3WKXTNEXJ9FXZC1
definite-fail: 01KSVZSQKZB3P1GVJTC7PJTSFN
```

## Interpretation

For today, we have a working but slow plan-validation workflow.

The documented fan-out/fan-in pattern does not currently provide enough accessible reviewer evidence to synthesis in this workflow, despite the docs suggesting `parallel_results.json` should be available.

The evals are useful: they prevented us from accepting a faster workflow that silently loses reviewer findings.

## Follow-up questions for Fabro/tooling

- Where exactly is `parallel_results.json` materialized for downstream nodes?
- Is it only in metadata snapshots / `fabro dump`, not in the sandbox working directory?
- Are prompt nodes expected to see branch response bodies in the preamble, or only branch status/head SHA metadata?
- Should parallel fan-in merge `response.<branch_node_id>` and `context_updates` from all branches into downstream context?
- Is there a supported way for a workflow to access every branch response after fan-in without using external `fabro dump` / event inspection?
- Are the docs/examples stale relative to server `0.245.0-nightly.0`?

## Recommendation

Keep the sequential plan-validation workflow until Fabro provides a reliable first-class way to pass all branch responses into synthesis.

Do not remove or weaken `.fabro/workflows/plan-validation/test.sh`; it is the safety net that caught the regression repeatedly.
