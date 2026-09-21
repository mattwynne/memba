---
name: kaizen-experiment-review
description: Review, evaluate, close, iterate, adopt, or revert a software-delivery factory experiment recorded in the kaizen ledger. Use when asked about a kaizen experiment or when the active Experiment review date is due; do not use for product A/B tests or CRO experiments.
---

# Kaizen Experiment Review

Evaluate whether a delivery-factory countermeasure produced the predeclared operational improvement without violating quality guardrails. This applies to workflows, skills, prompts, CI/dev tooling, Fabro, BB, model routing, handoffs, observability, and related delivery machinery—not product A/B tests or conversion optimization.

Operate autonomously through evidence gathering and a single recommendation. Obtain Matt's approval before material workflow or tool changes. After approval, continue through implementation, independent validation, documentation, and commit within the authorised scope.

## Select the Experiment

Read `docs/kaizen/README.md`. Its ledger contract is:

`First observed | Kaizen note | Status | Review due`

Valid statuses are `New`, `Open`, `Experiment`, and `Closed`, with at most one `Experiment` row.

- If there is no `Experiment`, report clearly that no experiment is active and stop.
- If there is exactly one, follow its linked kaizen note.
- If there is more than one, report a WIP=1 violation. Do not treat either selection as valid. Inspect the linked notes and history only far enough to explain the conflict and propose the safest correction; obtain approval before changing statuses.
- Treat a due or overdue `Review due` date as a reason to perform the review when encountered, even if the request only asks about experiment status.

Protect unrelated work with `git status --short --branch`. Do not overwrite or include unrelated changes.

## Recover the Contract

Read the linked note and identify:

- causal evidence and hypothesis;
- baseline and comparable measurement window;
- exactly one primary outcome metric;
- quality guardrails;
- implementation and its start point;
- validation ladder;
- review date; and
- predeclared Adopt, Iterate, or Revert criteria.

Missing or ambiguous contract fields are evidence gaps, not favourable results. Preserve what was actually predeclared; do not retroactively move thresholds to fit the observations.

## Gather Operational Evidence

Inspect the evidence relevant to the countermeasure, including as applicable:

- Fabro run history and logs, preserving run IDs and date ranges;
- git, PR, merge, release, and deploy history;
- token, cost, latency, model, and routing usage;
- `dev check`, tests, CI, and validation outcomes;
- incidents, regressions, retries, rollbacks, and escaped defects;
- human interventions, manual recovery, and handoff friction; and
- BB thread/run history and other durable workflow evidence.

Do not use absent telemetry or missing logs as evidence of success. Do not destroy Fabro history; in particular, never use `fabro rm` without Matt's explicit approval as a last resort.

Compare observed results with the baseline and declared criteria:

1. **Check quality guardrails first.** A faster or cheaper process is not an improvement if quality, safety, recoverability, or customer outcomes regressed beyond the contract.
2. Separate proof that the change was installed or functions from proof that it improved routine operations.
3. Check sample comparability, date-window recency, sample size, workload mix, model/tool changes, operator effects, and other confounders.
4. Seek disconfirming evidence and plausible alternative explanations. Inspect failures and outliers rather than averaging them away.
5. State uncertainty plainly. Prefer “insufficient evidence” over an unsupported success claim.

## Recommend One Outcome

Recommend exactly one:

- **Adopt** — guardrails hold and evidence meets the declared adoption criteria. Standardize the change, remove temporary scaffolding where appropriate, update its contracts/docs, validate, then close the ledger row.
- **Iterate** — the hypothesis remains plausible but evidence or implementation warrants one focused adjustment. Change one hypothesis or countermeasure at a time, preserve the learning, define the revised metric/criteria and a new review date, and keep the row `Experiment`. WIP remains occupied.
- **Revert** — guardrails fail, evidence meets revert criteria, or the countermeasure is not justified. Safely reverse experiment-specific changes, retain useful measurement only when justified, validate restoration, record the learning, then close the ledger row. Never erase evidence.

Explain the experiment, expected result, observed result, guardrails, recommendation, evidence, and uncertainty concisely without assuming Matt knows the context. Offer multiple options only when a genuine tradeoff prevents a responsible single recommendation. Ask for approval before material workflow/tool changes.

## Execute the Approved Decision

After approval, dispatch BB child threads for implementation and independent validation. Use isolated worktrees for code-changing delegated work. Keep ownership clear and reconcile results before accepting them.

Use a safe validation ladder appropriate to the change:

1. static checks and contract review;
2. fixtures or synthetic cases;
3. isolated replay of historical inputs;
4. limited canary only when earlier evidence supports it; and
5. broader use only after guardrails hold.

Never make a real production software-delivery run the first test of a factory change. Follow project-specific quality gates for executable changes. Prefer reversible steps and preserve logs.

Apply the selected outcome:

- **Adopt:** integrate and standardize, remove obsolete experiment-only scaffolding, and validate the resulting standard work.
- **Iterate:** alter only the approved variable, update the experiment contract and due date, and leave status as `Experiment`.
- **Revert:** reverse only experiment-specific behaviour, retain justified instrumentation, and prove restoration through the safe ladder.

Have the independent validator inspect both the implementation and the outcome-specific ledger/note consistency. A validator must not merely repeat the implementer's assertions.

## Record the Review

Update the experiment's kaizen note without erasing its original evidence. Record:

- expected versus observed results;
- evidence sources, run IDs, and date range;
- guardrail results and adversarial checks;
- confounders, evidence gaps, and residual uncertainty;
- recommendation, Matt's approved decision, and rationale;
- files and operational changes made;
- validation performed and results; and
- concrete follow-up, if any.

Update the ledger consistently:

- Adopt or Revert: `Status` = `Closed`; `Review due` = an em dash (`—`) or no date.
- Iterate: `Status` = `Experiment`; `Review due` = the newly agreed date.

Preserve WIP=1. Commit only the review implementation and its direct kaizen note/ledger updates; do not include unrelated work. Report the outcome, key evidence, validation, changed paths, commit SHA, and any residual uncertainty concisely.
