# Problem: Gemini credit exhaustion broke Fabro review synthesis

Date: 2026-06-19

## Context

We were using Fabro to finish the iteration queue in `docs/iterations/README.md`.

The immediate workflow step was a post-implementation review for iteration 037:

- Plan: `docs/iterations/037-ds-catchup-onboarding-requests-and-refresh/plan.md`
- Review run: `01KVFVZ30JXDYKWHZ39A2AF7BT`
- Web UI: `https://fabro.home.wynne.family/runs/01KVFVZ30JXDYKWHZ39A2AF7BT`

The review workflow expects independent Claude, Codex/GPT, and Gemini review reports before synthesis.

## Expected standard

Fabro review should either:

1. collect all required independent review reports and synthesize them;
2. fail quickly with a clear infrastructure/model-availability diagnosis before spending substantial review effort; or
3. have a configured fallback path when one review provider is unavailable due quota or credits.

A depleted model-provider balance should not waste a mostly completed review run or block the delivery queue after other reviewers and `dev check` have already succeeded.

## What happened

The review run progressed through repair and validation work, then reached the independent review stages:

- `claude_review` succeeded.
- `codex_review` succeeded.
- `gemini_review` failed three times.

The Gemini failure was:

```text
LLM error: Rate limited by gemini: Your prepayment credits are depleted. Please go to AI Studio at https://ai.studio/projects to manage your project and billing. Learn more at https://ai.google.dev/gemini-api/docs/billing#prepay.
```

After the final retry, the workflow routed to `synthesis_unavailable` and failed with:

```text
Iteration review could not collect and synthesize all independent review reports after retrying a transient LLM/provider failure. Product review evidence may exist in completed review stages; inspect the run events/artifacts and rerun or manually synthesize rather than treating this as reviewer rejection.
```

The immediate operator workaround was to route the `gemini_review` nodes in Fabro workflows to `gpt-5.5` and rerun the review.

## Impact

- The iteration 037 review failed for delivery-machinery reasons, not because reviewers rejected the implementation.
- Completed Claude/Codex review work and `dev check` evidence had to be inspected and rerun/duplicated.
- The queue paused while the model-routing problem was diagnosed and worked around.
- The failure repeated an earlier class of credit/quota-dependent Fabro interruption, but with a different provider.

## What allowed it to happen

- The workflow had a hard dependency on Gemini for the third independent review report.
- There was no preflight check proving the configured Gemini account had available prepayment credits before the run reached that stage.
- The provider-credit failure was treated as retryable transient rate limiting, even though the message indicated a durable billing/credit problem.
- The review workflow could not degrade to a same-provider substitute, skip the unavailable reviewer with an explicit reduced-confidence path, or fail before doing earlier expensive work.
- Model routing lived in workflow configuration rather than in a centrally checked provider-availability policy.

## Observations

- The failure appeared late in the run after multiple earlier stages had succeeded.
- `fabro inspect` and `fabro logs` showed enough evidence to classify this as provider-credit exhaustion.
- A previous note, `docs/kaizen/2026-05-28-credit-exhaustion-mid-run.md`, recorded a similar problem for Anthropic credits. This incident shows the weakness is not provider-specific.
- The run correctly avoided treating the failed synthesis as product rejection, but the recovery still required manual workflow/model routing changes.

## Why this matters

Fabro is supposed to provide reliable implementation and review throughput. If any hard-coded reviewer provider can run out of credits mid-run, the delivery queue becomes dependent on external account balances that are not checked before work starts. This creates avoidable waste and makes successful product work look blocked or unstable.

## Open questions

- Should Fabro classify provider messages like "prepayment credits are depleted" as terminal billing/configuration failures rather than transient rate limits?
- Should review workflows require three distinct providers, or is three independent reviews from available configured models sufficient?
- Where should provider-account health and model availability be checked before starting long Fabro workflows?
- Should workflow model routing be generated from a centrally maintained provider availability matrix instead of hard-coded in each workflow?

## Possible prevention ideas

- Add a Fabro preflight that probes every explicitly configured model/provider and fails before work starts when quota/credits are unavailable.
- Distinguish durable billing/credit exhaustion from transient rate limits in retry policy and error messages.
- Add fallback model routing for independent reviewer slots when a provider is unavailable.
- Periodically check configured provider balances/quotas and surface them in `fabro doctor` or a project delivery preflight.
- Keep a single project-level model-routing policy so plan validation and review do not drift into stale provider assumptions.

### Additional observation: 2026-09-21 factory retrospective

The failure class recurred after model-routing changes. Of eight iteration-review runs from 2026-09-13 onward, five failed at `synthesize_review` because one required reviewer produced no usable report:

- `01M2GFYQR4NV7T7FFQF833WY79`
- `01M2GHF4W1R9AANP8NVKAZRC0Q`
- `01M30SK3NT65YGJ6T9BGJ8TAKK`
- `01M31EBMGHK7FJKVEW624KB202`
- `01M31EMV03T23KFC1MVMVPRNYH`

The first three directly logged OpenRouter HTTP 402. In the two later forks, Claude evidence was absent while Sol and Gemini both returned usable `ACCEPT` reviews; the matching cause is likely but not directly proven. One run spent 27m37s after `dev ci` had already passed before terminating for unavailable synthesis.

The current graph fans out to Claude, Sol and Gemini but sends `review_merge` to `synthesis_unavailable` unless every branch succeeds. `synthesize_review` declares `allow_partial=true`, so the fan-in availability rule—not synthesis capability—is the immediate hard dependency.

This note is now assessed as **Open**. Restoring credits is containment, not recurrence prevention: May Anthropic exhaustion and this note's June Gemini exhaustion show that the weakness follows whichever external provider is mandatory.

## Proposed experiment: availability-tolerant independent-review quorum

Status: awaiting approval. Do not change the ledger to `Experiment` or alter the workflow until Matt approves this contract and review date.

Hypothesis: allowing synthesis with at least two usable independent reports from distinct configured model/provider routes will prevent a single unavailable reviewer from terminating otherwise reviewable work, without reducing defect detection or bypassing a negative verdict.

Baseline: 5/8 iteration-review runs from 2026-09-13 onward terminated at synthesis because one required reviewer was unavailable; three are directly tied to HTTP 402. Historical May and June notes show the same class across Anthropic and Gemini.

Primary outcome metric: **eligible review completion rate** — the proportion of review runs with at least two usable independent reports that reach a synthesized product verdict rather than terminating solely for reviewer unavailability. Baseline for the five affected runs: 0/5. Proposed operational target: 5/5 qualifying runs after rollout.

Quality guardrails:

- require at least two usable independent reports from distinct configured routes;
- never convert absence or provider failure into an acceptance verdict;
- any received blocking or reject finding must continue into repair or a fail-closed outcome;
- fewer than two usable reports remains terminal;
- retain `dev check`, exact-candidate attestation, artifact, plan-conformance and publication gates;
- historical replay must not lose a blocking finding or produce a more permissive verdict than the existing complete-review synthesis without an explicit investigated explanation.

Proposed implementation: make review fan-in classify usable, unavailable and negative reviewer outcomes deterministically; pass the available reports and explicit absence metadata to synthesis only when the quorum and guardrails hold. Preserve all three reviewer calls in normal operation. Record reviewer availability, verdict, provider/model, elapsed time and whether quorum mode was used.

Validation ladder before routine delivery:

1. Static graph/schema checks and deterministic fixtures for 3/3 usable, 2/3 usable, fewer than two usable, one unavailable plus one negative, and synthesis failure.
2. Replay the five affected runs' retained reports and a corpus of successful reviews containing accepted and blocking findings; compare the quorum result with full-review decisions where available.
3. Run an isolated historical review with publication and product side effects disabled.
4. Only after those pass, use a limited canary while retaining all ordinary quality and publication gates.

Proposed decision criteria:

- **Adopt:** deterministic and historical replay guardrails pass; the next five qualifying operational reviews reach a verdict without an availability-only terminal failure; no blocking finding is lost and no quality guardrail regresses.
- **Iterate:** quality guardrails hold but fewer than five qualifying runs exist by the review date, or observability/implementation defects prevent a fair comparison; change one variable or extend only the evidence window.
- **Revert:** quorum mode loses or suppresses a blocking finding, accepts with fewer than two usable independent reports, bypasses another gate, or creates a quality regression plausibly attributable to reduced review evidence.

Proposed review date: 2026-10-19, with at least five qualifying reviews required for adoption. If the sample is smaller, retain the criteria and extend the collection window rather than declaring success.

Source: [2026-09-21 software factory retrospective](../notes/2026-09-21-software-factory-retrospective.md).

## Approved experiment: simplify post-merge review into a healer

Status: Experiment

Approved: 2026-09-21

The quorum proposal above was rejected during decision discussion. Two of the three reviewers currently depend on OpenRouter, so a two-report quorum would still fail during a full OpenRouter outage. Provider-aware fallbacks would add machinery to preserve multi-provider review before its incremental value has been demonstrated.

Rename the former standard post-merge workflow and canonical command to `code-review` and make its purpose explicit: it is a non-gating healer for trunk-based development. Implementation may merge to `main` first. Code review then produces zero or more follow-up improvements and must not retroactively turn successful delivery into failure.

Hypothesis: one focused OpenAI reviewer with explicit clean/heal/record/escalate outcomes will complete more reliably and cheaply than three-provider fan-out and synthesis while retaining the useful code-health and bounded-polish outcomes.

Baseline:

- 5/8 recent `iteration-review` runs terminated at synthesis because one reviewer was unavailable.
- The current workflow requires three reviewer reports and a synthesis stage.
- Five `docs/code-health.md` sections explicitly say synthesis omitted independent-review findings and the recorder recovered them.
- Review currently reruns a full gate before reviewing even though implementation already validated the exact candidate.
- Review completion is synchronously coupled to `bin/dev fabro deliver` after implementation has already merged.

Primary outcome metric: **hands-off code-review completion rate** — the proportion of launched post-merge reviews that reach clean, healed, recorded, or explicitly human-paused state without infrastructure/provider recovery. Proposed adoption target: at least 5/5 qualifying code reviews.

Quality guardrails:

- Historical replay must retain the consequential findings and bounded improvements selected from representative prior reviews.
- The reviewer must distinguish clean, bounded automatic healing, non-urgent recording, and consequential human judgement.
- Behavioural gaps, ADR/architecture decisions, migrations or production-data risk, security/privacy concerns, broad cross-cutting changes, and repeated/no-progress healing attempts must not be silently auto-fixed.
- A bounded code/config/test change must pass the project-required `dev check` on its exact final state before publication.
- Non-blocking findings must remain durable; clean or infrastructure outcomes must not erase review evidence.
- Implementation publication and production delivery remain independent of healer success.

Slice 1 implementation:

1. Rename workflow and user-facing command to `code-review`, retaining a narrow compatibility alias only if it materially reduces migration risk.
2. Launch code review asynchronously after implementation reaches `main`; return its run ID/link rather than waiting for completion.
3. Replace reviewer fan-out and synthesis with one focused OpenAI reviewer and explicit routing.
4. Allow at most one bounded automatic healing pass before reclassification or human escalation.
5. Record non-urgent findings in `docs/code-health.md`.
6. Route consequential findings to a Fabro human gate with safe choices and free-form direction. Use Fabro's web/CLI interviewer initially; Slack is explicitly out of scope.
7. Do not pass `--auto-approve` to code review, because that would bypass real human involvement.

Validation ladder before a live canary:

1. Static graph/schema/command tests for renamed paths and removal of the three-review/synthesis dependency.
2. Deterministic routing fixtures for clean, bounded heal, record, consequential human gate, no-progress heal, provider failure, publication/no-op, and unanswered human input.
3. Historical replay fixtures using representative retained reviewer findings, including findings previously omitted by synthesis.
4. Full `dev check` on the exact implementation state.
5. Only after these pass, launch a limited code-review canary; do not use a production delivery as the first test.

Decision criteria:

- **Adopt:** validation passes; 5/5 qualifying reviews reach a valid terminal or explicit human-paused state without infrastructure recovery; historical consequential findings remain visible; bounded changes pass exact-state validation; no quality regression is attributable to simplification.
- **Iterate:** guardrails hold but fewer than five qualifying reviews exist, classification thresholds need one focused adjustment, or observability prevents a fair comparison.
- **Revert:** the simplified reviewer loses a consequential historical finding, silently auto-fixes a judgement-heavy change, publishes without required validation, or couples healer failure back into delivery success.

Review due: 2026-10-19, requiring at least five qualifying reviews for adoption. Slack integration is a later optional slice and is not part of this experiment.

### Slice 1 implementation and validation

Implemented locally without launching a live delivery or code-review run:

- Renamed the workflow directory and canonical helper to `code-review`; `bin/dev fabro review` remains only as a deprecated forwarding alias.
- `bin/dev fabro deliver` now waits only for implementation publication, then launches the healer with `--detach`, reports the run ID, web URL and recovery/status commands, and preserves successful delivery if launch fails.
- Replaced Claude/Sol/Gemini fan-out and synthesis with one explicitly routed OpenAI GPT-5.6 Terra reviewer, distinct from the routine GPT-5.6 Sol implementation/repair assignment.
- Added explicit clean, one-pass bounded heal, durable record and consequential-human routes. Clean skips the full gate; bounded code/config/test healing requires exact-state `dev check`; docs-only code-health publication skips that unnecessary gate.
- Added a fail-closed `shape=hexagon` consequential gate with record/defer, prepare separately approved follow-up, dismiss-with-rationale and freeform options. Canonical launch does not pass `--auto-approve`.
- Retained concurrent-main-safe follow-up publication and added disposition, human-pause, heal-publication and elapsed observability in Fabro stage output. The Fabro event envelope is the authoritative run identity; the helper also records `FABRO_RUN_ID` when the sandbox provider exports it.
- Deleted obsolete fan-out/synthesis prompts and graph machinery.

Validation includes static graph/schema/command assertions; deterministic no-model graph routing fixtures for clean, bounded heal, record, consequential, no-progress, provider failure, publication/no-op, unanswered input and detached launch; route-specific observability assertions for disposition, human pause, publication state and elapsed time, with run identity correlated through the Fabro event envelope; source-backed prompt-contract examples for an ADR 0024 aggregate-boundary finding and two findings omitted by synthesis; native helper tests; Fabro graph validation; and the required exact-state `dev check`.

The scripted graph fixtures validate deterministic routing after a disposition is supplied; they do not test LLM classification. The historical examples verify only that retained source excerpts exist and the reviewer prompt states the applicable contract thresholds. Neither establishes classification quality or operational effectiveness; adoption still requires the 5/5 qualifying operational sample and guardrails above.

### Integrated-review corrections — 2026-09-22

Independent validation found that preflight captured whichever `origin/main` existed when preflight ran, rather than the candidate selected when the detached review was launched. If `main` advanced from candidate A to B in that interval, publication could construct an inverse stale-tree diff. The correction now passes the launch candidate SHA as an explicit workflow input, requires the sandbox tree to match that candidate (allowing only tree-identical Fabro checkpoints), records that identity as publication provenance, and rebases only the A-based follow-up commit onto freshly fetched main. A later non-fast-forward push still fails closed.

Correction evidence, using no model calls or external repositories:

- `test_preflight_sandbox.sh` holds the review on A, advances the temporary bare origin's main to B before preflight, proves preflight records A rather than B or the checkpoint commit, and proves a retargeted sandbox fails closed.
- `test_publish_polish_to_main.sh` reproduces A → concurrent B → preflight → healer change → publish for both bounded-heal and docs-only record paths; B's independently added file survives in both published trees.
- `test_code_review_runtime.py` runs a native local Fabro server while retaining the production graph edges. Scripted nodes supply dispositions without model calls, while representative deterministic production helpers perform sandbox preflight, evidence collection, repair-progress verification, and observability recording. It executes clean, heal, record, consequential, invalid-fallthrough, and no-progress routes; verifies one repair pass; verifies unanswered human input remains paused; verifies observability output; and verifies explicit `--auto-approve` selects the first safe record/defer choice. This is runtime routing evidence after a supplied disposition, not classification-quality or operational-effectiveness evidence.
- `test_code_review_launch.sh` executes the real `bin/dev fabro code-review` helper against fake local Fabro responses. It covers canonical and shell-hostile plan paths, ancestor and non-ancestor explicit bases, detached launch arguments, run-ID extraction after a nonzero launch command, succeeded/failed/active/unknown remote status handling, monitoring guidance, interrupted-launch cleanup, and temporary-worktree cleanup.

No live delivery or code-review canary was launched for these corrections. The experiment remains `Experiment`; no operational completion-rate or quality-effectiveness claim is made.
