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

## Additional observation: 2026-06-08

### Context

We inspected the `iteration-review` workflow after Matt observed that code review "never seems to come back with anything." The reviewed workflow was `.fabro/workflows/iteration-review/workflow.fabro`, with reviewer and synthesis prompts under `.fabro/workflows/iteration-review/prompts/`.

Recent review runs inspected:

```text
01KTCS5B6M5RQS0SV9XA5QZ31M  docs/iterations/021-staff-area-redesign/plan.md
01KTJC3F29TAD4HV6RP4DJRCM7  docs/iterations/027-membership-administrator-role/plan.md
```

### Expected standard

The iteration review workflow is supposed to run independent Claude, Codex/GPT, and Gemini reviews, synthesize their reports, apply bounded-safe fixes where appropriate, and record judgement-worthy non-blocking findings in `docs/code-health.md`.

A successful review should not mean only that the reviewer branches completed. It should mean the synthesis step has actually seen and accounted for the reviewer reports.

### What happened

Both recent review runs used parallel fan-out/fan-in for the independent reviewer stages. In both runs, the individual reviewer stages completed and produced substantive reports, but the downstream synthesis context only exposed branch metadata such as:

```text
parallel.branch_count
parallel.fan_in.best_head_sha
parallel.fan_in.best_id
parallel.fan_in.best_outcome
parallel.results
```

The synthesis prompt did not receive the full reviewer response bodies.

Evidence from `01KTJC3F29TAD4HV6RP4DJRCM7`:

- `gemini_review` returned a 2,245 character report and listed judgement-worthy code-health findings.
- `codex_review` returned a 3,045 character report and listed judgement-worthy code-health findings.
- `claude_review` returned a 10,367 character report and recommended bounded-safe fixes.
- `synthesize_review` returned only tool-call-looking JSON plus routing:

```text
{"cmd": "ls -R .fabro | sed -n '1,200p' && echo '---' && find .fabro -type f -maxdepth 4 -print"}{"cmd": "find .fabro -maxdepth 4 -type f -print | sort | sed -n '1,200p'"}{"context_updates":{"implementation_accepted":true,"review_fixes_available":false}}
```

The workflow then routed through `record_code_health`, which also emitted tool-call-looking JSON and concluded that `docs/code-health.md` did not need an entry.

Evidence from `01KTCS5B6M5RQS0SV9XA5QZ31M` showed the same pattern: all three reviewers produced substantive reports, including bounded-safe and judgement-worthy findings, but synthesis accepted with no fixes and no code-health findings.

### Impact

This created false-clean review results. The workflow spent model time finding useful issues, but then silently discarded the findings before the gate that decides whether to polish code or record code-health notes.

The impact is quality risk rather than an immediate production bug:

- bounded-safe fixes can be skipped;
- judgement-worthy architecture or maintainability concerns do not reach `docs/code-health.md`;
- Matt sees repeated successful reviews that appear to have found nothing;
- diagnosis requires manual archaeology through `fabro events` rather than reading the final review output.

### What allowed it to happen

The same Fabro parallel fan-in evidence gap observed in plan validation also existed in iteration review. The workflow trusted parallel branch success metadata as if it implied reviewer report visibility.

Missing or weak protections:

- no guardrail checked that synthesis could see each reviewer body's Markdown before accepting;
- no shape validation rejected synthesis responses that were only tool-call JSON plus routing JSON;
- `record_code_health` relied on synthesis, so it inherited the blind spot;
- there was no eval/test equivalent for iteration review that plants reviewer findings and proves they reach synthesis/code-health recording.

### Observations

- This is not a reviewer-quality problem: the individual review stages did produce useful reports.
- This is not a product-code problem: the abnormality is in workflow evidence handoff after parallel fan-in.
- The problem recurred after the same failure mode had already been documented and worked around in plan validation.
- A tactical fix was applied in commit `82f1eee3` (`Harden iteration review synthesis`): iteration-review now runs the reviewer stages sequentially and the prompts fail closed if reviewer Markdown is not visible.

### Why this matters

Review is the last delivery-machine step meant to catch maintainability, ADR, and code-health signals after implementation. If the workflow can report a clean review while dropping reviewer findings, it weakens trust in successful runs and lets review debt accumulate invisibly.

### Open questions

- Should iteration review have an eval/test fixture like plan validation, with planted reviewer outputs that must reach synthesis and `docs/code-health.md`?
- Can Fabro expose all parallel branch responses as first-class downstream context so the workflow can safely regain parallelism?
- Should prompt response shape validation reject tool-call-looking JSON before routing context updates are accepted?

### Possible prevention ideas

- Keep iteration-review sequential until Fabro provides reliable fan-in evidence visibility.
- Add an iteration-review workflow eval that fails if reviewer findings are omitted by synthesis.
- Add a deterministic synthesis preflight/guardrail: require visible `response.claude_review`, `response.codex_review`, and `response.gemini_review` content before accepting.
- Treat malformed synthesis output, especially command JSON followed only by routing JSON, as an infrastructure failure rather than a clean review.
