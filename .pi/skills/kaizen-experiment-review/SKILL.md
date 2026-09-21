---
name: kaizen-experiment-review
description: Evaluate an active software-delivery factory experiment against its predeclared metric and guardrails, then recommend Adopt, Iterate, or Revert. Use for a named active kaizen experiment or when its ledger review date is due—not for launching experiments, ordinary kaizen fixes, broad retrospectives, incidents, or product/CRO tests.
---

# Kaizen experiment review

Evaluate whether an approved delivery-factory countermeasure improved routine operations without violating quality guardrails. Factory scope includes skills, prompts, CI/dev tooling, Fabro, BB, model routing, handoffs, and observability; product experiments belong elsewhere.

Work autonomously through evidence collection and one recommendation. Ask only when essential evidence is inaccessible, the target is ambiguous, or business context changes the decision. Obtain Matt's approval before changing factory behaviour, tooling, experiment terms, or ledger status.

## Select and time the review

Read `docs/kaizen/README.md` and preserve its exact columns:

`First observed | Kaizen note | Status | Review due`

Allowed statuses are `New`, `Open`, `Experiment`, and `Closed`; at most one row may be `Experiment`.

1. Run `git status --short --branch` and protect unrelated work.
2. If the request names a note, resolve it exactly. If it is not the active `Experiment`, report its status; do not silently review another row or treat the named note as active. Mention any different active experiment and route New/Open work to investigation or experiment design.
3. Without a named target, select the sole `Experiment`. If none exists, answer status or audit questions usefully, but do not invent a review or launch an experiment. Explain the next applicable action rather than stopping without guidance.
4. If multiple rows are `Experiment`, report the WIP=1 violation. Inspect only enough history to explain it and recommend the safest correction; approval is required before changing statuses.
5. Infer whether review is due by comparing `Review due` with the current date. Due or overdue triggers review. A requested early review also proceeds but calls out its shortened window; a status check before the date does not trigger full review.

A due date is a prompt, not proof of an adequate sample.

## Recover the predeclared contract

Read the linked note and recover what existed before results were known:

- causal evidence and hypothesis;
- baseline and comparable measurement window;
- exactly one primary outcome metric;
- quality guardrails;
- implementation and start point;
- validation ladder;
- review date; and
- Adopt, Iterate, and Revert criteria.

Do not retrofit metrics, thresholds, baselines, or guardrails. Missing or materially ambiguous fields are evidence gaps. A weak baseline, primary metric, or guardrail rules out **Adopt**: recommend **Iterate** with a prospective, approval-gated contract repair when safe and worthwhile, otherwise **Revert**. Pre-repair observations may inform the new design but cannot satisfy its adoption criteria; measure effectiveness in a fresh, comparable window after the repaired contract is approved.

## Evaluate evidence

Use evidence relevant to this countermeasure: Fabro run IDs/logs; git, PR, release, or deploy history; cost, token, latency, model, or routing data; CI/tests/`dev check`; incidents, defects, retries, rollback, manual recovery, handoff friction; and durable BB history. Record source, date range, and sample size. Missing telemetry is not success. Preserve Fabro history; never use `fabro rm` without Matt's explicit approval as a last resort.

Compare the experiment window with its baseline and declared criteria:

1. Evaluate quality, safety, recoverability, and customer guardrails before speed or cost.
2. Separate implementation validation (installed and functioning) from effectiveness (improved routine outcomes).
3. Check comparability: workload mix, sample size, recency, operator, model/tool changes, seasonality, and concurrent changes.
4. Make an adversarial pass: seek disconfirming evidence, inspect failures and outliers, and test plausible alternative explanations.
5. Name missing data and uncertainty; never average away a guardrail failure or infer success from absence.

If review is due before the declared sample is reached, still conclude it but do not Adopt. When continued exposure is safe and informative, recommend **Iterate** by retaining the original metric, thresholds, guardrails, and sample target and extending only the collection window and review date. Recommend **Revert** when guardrails fail, exposure is unsafe, or more evidence is not worth its cost.

## Recommend one outcome

Briefly state what changed, expected versus observed result, guardrails, strongest evidence, confounders, missing data, and uncertainty. Recommend exactly one:

- **Adopt** — guardrails hold and declared adoption criteria are met.
- **Iterate** — one focused implementation adjustment, prospective contract repair, or bounded evidence extension is justified. For an extension, preserve the contract and change only the date. For a repair, declare the metric and criteria prospectively and start a fresh measurement window. Define one path and its new review date; WIP remains occupied.
- **Revert** — guardrails fail, revert criteria are met, or continued use is unjustified.

Recommend one outcome even under uncertainty, and state what evidence could change it; do not replace the recommendation with a menu. Ask for approval before material action. Recording evidence and the recommendation does not authorize behaviour or status changes.

## Execute only after approval

After approval, dispatch one BB child thread to implement and another to validate independently. Use isolated worktrees for code changes. Reconcile evidence; the validator must inspect implementation and note/ledger consistency, not repeat the implementer's claims.

Validate from safest to broadest: static/contracts, fixtures or synthetic cases, isolated historical replay, then a supported limited canary. Never make a real production delivery the first test of a factory change. Run `dev check` for code, config, dependency, migration, acceptance-test, or app-behaviour changes, and report it passing only for the exact final state or an equivalent clean worktree with the same diff staged. Skill/docs-only changes need no `dev check` unless requested or executable examples change.

- **Adopt:** standardize, remove obsolete experiment scaffolding, validate, then close.
- **Iterate:** apply only the approved adjustment, prospective contract repair, or date extension; validate, set the new date, and retain `Experiment`.
- **Revert:** reverse only experiment behaviour, retain justified instrumentation, validate restoration, then close.

## Preserve the learning

Update the kaizen note without erasing its original contract or evidence. Record expected and observed results; sources, run IDs, dates, and sample; guardrails and adversarial checks; confounders and gaps; recommendation and approved decision; changes; independent validation; and follow-up.

Update the ledger only after approval:

- Adopt/Revert: `Status` = `Closed`, `Review due` = `—`.
- Iterate: `Status` = `Experiment`, `Review due` = the approved new date.

Preserve WIP=1. Commit only direct implementation, note, and ledger changes; exclude unrelated work. Report outcome, evidence, validation, paths, commit SHA, and residual uncertainty.
