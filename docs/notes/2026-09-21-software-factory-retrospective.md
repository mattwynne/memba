# Software factory retrospective — 2026-09-21

Window: 2026-06-23 through 2026-09-21 inclusive (90 days), with recent evidence weighted most heavily.

## Objective

The review optimized, in order, for:

1. successful hands-off change throughput;
2. idea-to-production lead time;
3. token cost per successful change;

A successful change starts with an approved, dispatched iteration and reaches production without operator rescue, restart, workaround or failed-run nursing, while preserving code quality.

## Evidence inventory

Four parallel read-only investigations covered:

- iteration plans and outcomes, Git/run branches, merges, release/deploy and CI evidence;
- remote Fabro run metadata, events and logs, plus repository run/checkpoint history;
- `dev check`, acceptance tests, incidents, code-health findings and kaizen notes;
- BB threads, human interventions, model/context usage and handoff observability.

Broad evidence included 157 remote Fabro records (156 terminal), 149 repository-qualified run IDs, 3,179 stage-result commits, iteration and kaizen history, incident records, workflow source, and the available BB thread history.

Important gaps:

- BB covered only about 40.5 hours of the 90-day window, so absence of older intervention records is not evidence of hands-off delivery.
- Merge history is available, but no reliable record links every merge to production availability. Lead-time figures are therefore idea/implementation-to-main proxies, not idea-to-production measurements.
- Fabro dollar figures are API-equivalent metadata; OpenAI work may be subscription-covered.
- There is no durable per-delivery ledger joining iteration, Fabro runs, human interventions, candidate SHA, validation, merge, deploy and provider usage.

Research used four BB children over about 22.5 elapsed minutes. Their latest estimated context usage totalled 664,866 tokens; this is not cumulative billable usage. No destructive commands or `fabro rm` were used.

## Current factory baseline

- Fabro terminal success was 77/156 (49.4%) across the server window. The denominator mixes workflow types and expected gate rejections, so it is a run-health signal rather than successful-change throughput.
- Fifteen Git-pairable implementation-start-to-delivery intervals had a 6.5-hour median; 12/15 were under 24 hours. A broader plan-commit-to-merged proxy across 18 completed iterations had a 31.35-hour median. Neither proves hands-off operation or production deployment.
- Recent retained BB evidence showed 77 follow-up human prompts beyond initial dispatch across 14 pre-retrospective operational threads. This sample is recent and small but directly contradicts the desired hands-off standard.
- A clean `dev check` took 17m48.9s, with browser acceptance consuming about 84%. Iteration 063 accumulated about 38 minutes of check/test shell time inside a 133-minute run.
- Several recent safeguards have strong fixture or focused regression evidence: exact-checkout validation, composite gate exit status, LiveView readiness, planner artifact guards, task-verdict routing, and exact-commit attestation. Many still lack enough subsequent routine deliveries to establish operational effectiveness.

## Candidate ranking

### 1. Remove the hard availability dependency on every configured review provider

From 2026-09-13 onward, 5/8 `iteration-review` runs failed at synthesis because one required reviewer produced no usable evidence. Three failures directly logged OpenRouter HTTP 402; two later forks had the same empty-Claude pattern while Sol and Gemini both returned usable `ACCEPT` reviews. One failure consumed 27m37s after `dev ci` had already passed.

This is recurrent rather than provider-specific: Gemini credit exhaustion blocked review in June, and Anthropic credit exhaustion terminated a nearly complete implementation in May. The current fan-in requires every review branch to complete before synthesis, despite `synthesize_review` itself permitting partial input.

Why ranked first: the cause is repeated, current, directly blocks otherwise-green work, consumes retries and operator attention, and is relatively tractable. A guarded two-of-three availability quorum can be tested against retained reviews without weakening tests, publication gates, or the handling of an actual negative verdict.

Confidence: high that the availability dependency exists; medium-high that a quorum is the best countermeasure until historical replay tests its quality sensitivity.

### 2. Replace the iteration-wide revision allowance with a task-scoped convergence policy

All 16 runs started on 2026-09-21 failed. The latest two substantive runs exhausted the iteration-wide `revise_task` visit limit after completing 26 checkpoints. Together with the preceding planner-guard failure, three attempts consumed 5.61 hours, $248.02 API-equivalent cost and about 65.1 million reported tokens without publishing iteration 064. The full iteration-064 sequence was 16/16 failed, 7.63 run-hours and $273.66.

This may be the largest current waste, but it ranked second because the independent review findings appear substantive. Merely raising a limit could amplify waste. Evidence does not yet distinguish an undersized global budget from poor packet sizing or genuinely indivisible work. It needs deeper causal work before selecting a safe countermeasure.

### 3. Remove duplicate and unnecessarily broad quality-gate work

Browser scenarios grew 43% while the faster comparable duration grew 106%. Twenty-eight domain scenarios are executed redundantly by global and feature-specific runners. Prompt policy now tells workers to use focused tests and reuse evidence, but routine-run effectiveness is not demonstrated.

This has clear lead-time value and high tractability for duplicate removal, but it does not explain as many terminal delivery failures as the first two candidates.

### 4. Make exact-candidate validation non-bypassable repository-wide

The window contains several independent false-green or wrong-candidate paths, including a passing browser suite masking precommit failure, tests running from another checkout, and commits reaching `main` when acceptance could not start. Recent fixes now bind checkout identity, preserve composite exit status, attest a clean final SHA, and gate deployment in CI.

The residual direct-push risk is serious, but recent controls mean the historical incidents should not outrank unfixed current failures without further recurrence evidence.

### 5. Make dispatch-to-publication ownership and telemetry explicit

Recent BB threads show repeated prompts for updates, recovery, validation and publication. Recovery state is distributed across run events, branches, threads and notes. A single durable handoff linking owner, first failing boundary, candidate SHA, validation, retry safety and publication would reduce archaeology and enable the desired throughput metric.

This is strategically important, but it is broader and less immediately testable than the selected reviewer-availability problem.

## Adversarial check of the selection

- **“Just top up OpenRouter.”** This is cheaper immediately, but the same class has occurred with Anthropic and Gemini. Account balance remains a single external availability dependency and does not prevent late-run waste.
- **“Two reviews may miss the unavailable reviewer’s unique defect.”** Correct; availability must not be treated as acceptance. The proposed experiment requires at least two usable independent reports, fails closed on any received blocking finding, and must replay historical reviews with known findings before any canary.
- **“Fix revision exhaustion first because it wasted more.”** Its current cost is larger, but its causal mechanism is ambiguous and a higher budget can increase waste. Reviewer availability has a clearer mechanism, repeated evidence, and a safer isolated test path.
- **“The five failures are all proven billing failures.”** Only three contain direct HTTP 402 evidence. The other two have the same missing-Claude shape and are labelled as inferred, not proven.
- **“One successful review proves the existing policy works.”** A 2026-09-14 review did succeed in 40m28s for $3.28, showing all-provider review can work when services are available; it does not refute the observed availability fragility.

The leader remained stable after these checks because it offers the best expected throughput improvement per implementation and validation effort without relaxing product quality gates.

## Selected recommendation

Run a bounded experiment for an **availability-tolerant independent-review quorum**:

- Preserve three reviewers when available.
- Permit synthesis when at least two usable independent reports from distinct configured model/provider routes exist.
- Never treat provider absence as an `ACCEPT` verdict.
- Any received blocking/reject finding continues to require repair or a fail-closed outcome.
- Fewer than two usable reports remains terminal.
- Keep `dev check`, exact-candidate, artifact and publication gates unchanged.

The detailed proposed contract and evidence are recorded in [the selected kaizen note](../kaizen/2026-06-19-gemini-credit-exhaustion-breaks-review-workflow.md). The ledger remains `Open` until Matt explicitly approves launching the experiment.

## Runners-up retained for later review

- Diagnose iteration-wide revision exhaustion against packet/task complexity before changing the budget.
- Remove the 28 known duplicate domain scenario executions and add per-feature browser timing.
- Measure operational effectiveness of the just-in-time planner and focused-test evidence reuse.
- Join dispatch, run, validation, merge, deploy, intervention and provider usage into one durable delivery record.
- Reassess repository ruleset/required-PR enforcement after current exact-SHA controls have representative operational evidence.

## Decision update — 2026-09-21

The initial availability-quorum recommendation exposed a simpler architectural question. Claude and Gemini both use OpenRouter, so a two-report quorum still fails during a provider-wide outage; fallback routing would add complexity before multi-provider review's marginal value is measured.

Matt confirmed the trunk-based intent: implementation may merge to `main`, and post-merge review is a healer that can contribute one or more follow-up improvements rather than a delivery gate. He approved a revised experiment to rename the workflow `code-review`, use one OpenAI reviewer, route bounded improvements autonomously, record non-urgent findings, and use Fabro's human gate for consequential findings. Code review will launch asynchronously after merge so its completion cannot block delivery. Slack is deferred; Fabro's existing web/CLI interviewer is sufficient for the experiment.

The approved contract and review criteria are recorded in [the selected kaizen note](../kaizen/2026-06-19-gemini-credit-exhaustion-breaks-review-workflow.md).
