# Deep retrospective protocol

## 1. Establish scope and inventory

Anchor the configurable evidence window to review start (default 90 days). Inventory all available sources before ranking:

- iteration plans, outcomes, and production state;
- Fabro run history, events, logs, failures, retries, checkpoints, and durations;
- Git commits/branches, PRs, merges, deploys, and CI/CD;
- token and model usage/cost;
- `dev check`, focused tests, and other quality-gate results;
- kaizen notes, incidents, regressions, and code-quality evidence;
- human intervention prompts, approvals beyond the initial dispatch, restarts, rescues, and manual fixes;
- relevant BB threads and child-thread outcomes.

Record unavailable sources and retention gaps explicitly. Do not translate a missing run, deploy, cost, or intervention record into success.

Start up to four BB research children in parallel, sized to the available evidence, with distinct domains such as (1) iterations/Git/deploy/CI, (2) Fabro runs, (3) tests/incidents/kaizen, and (4) BB/human interventions/token cost. Require source paths, IDs, dates, and uncertainties in each report. A child with no accessible evidence reports the gap rather than borrowing another child's scope.

## 2. Search broad, then drill down

First collect cheap metadata across the full window: counts, statuses, durations, timestamps, retries, costs, and links/identifiers. Then inspect anomalies plus recent representative successes and failures. Include successful deliveries so the review can distinguish systemic causes from isolated noise.

Corroborate the leading problem with at least two independent source types. Independence means different records or mechanisms, not two summaries copied from the same run log.

## 3. Rank candidates

Compare candidates on:

- frequency and recency;
- number and severity of human interventions;
- lead-time impact;
- token/model waste;
- rework and quality risk;
- tractability and implementation effort;
- evidence confidence.

Respect the objective order: quality-preserving successful-change throughput outranks lead time, which outranks token cost. Choose the best expected improvement per effort; avoid false numerical precision when measurements are weak. A frequent recent problem can outrank a dramatic old issue that is already controlled.

Investigate runners-up only enough to make the comparison defensible. Preserve evidence already found.

## 4. Challenge the leader and stop deliberately

Run an adversarial disconfirmation pass:

- look for counterexamples and successful runs under the same conditions;
- check whether a later fix already controls the issue;
- test alternative causes and denominator choices;
- identify evidence that would reverse the ranking;
- challenge policy, workflow, prompt, model, test, and ADR assumptions.

Stop when the leader remains stable and no plausible higher-value contender remains. Default safety cap: two elapsed hours, configurable by the request. Record elapsed time, subagent/model/token usage, and unavailable usage data when possible.

## 5. Recommend one action

Explain the top problem, causal mechanism, operational impact, supporting evidence, confidence, and main uncertainty. Recommend one improvement unless a real business or technical tradeoff requires options. State why runners-up lost.

Ask Matt to approve the recommendation before implementation. Approval to conduct the retrospective is not approval to change the factory.

If the ledger already has an `Experiment`, stop and invoke the sibling `kaizen-experiment-review` skill. Do not duplicate that skill's review procedure here and do not start a second experiment.

## 6. Implement safely after approval

After Matt approves the selected action, delegate implementation and independent validation to separate BB child threads. Define the validation ladder before making the change:

1. static checks and contracts;
2. deterministic fixtures;
3. isolated replay of representative historical successes/failures;
4. limited non-production canary.

Advance only with evidence from the prior rung. Preserve production delivery from first-test risk. If the machinery cannot be exercised safely outside a real delivery, treat that missing harness as a candidate improvement and say what evidence remains unavailable.

Update the selected kaizen note and ledger without rewriting historical observations. Repeated evidence belongs in the note. Keep at most one `Experiment` row.
