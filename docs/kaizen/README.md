# Kaizen ledger

This ledger indexes every top-level Markdown note in `docs/kaizen/`. Repeated occurrences and evidence belong in the linked note, not in extra ledger columns.

## Status semantics and WIP

- **New** — captured, not assessed.
- **Open** — assessed and worth addressing.
- **Experiment** — an approved experiment currently in progress. **WIP limit: at most one.** If one exists, review it through the sibling `kaizen-experiment-review` skill instead of starting another.
- **Closed** — no further action is intended, or the outcome is documented.

Use `Review due` only for the agreed review date of an active experiment. Use `—` for New, Open, and Closed; do not infer triage dates. Classify from evidence in the note or an explicit decision, not from headings, age, proposed exercises, or experiment-like language.

## Ledger

| First observed | Kaizen note | Status | Review due |
| --- | --- | --- | --- |
| 2026-09-20 | [Problem: Postgres validation failure did not block merge](2026-09-20-postgres-validation-failure-did-not-block-merge.md) | Open | — |
| 2026-09-14 | [Problem: Test feedback cost outgrew the implementation loop](2026-09-14-test-feedback-cost-outgrew-implementation-loop.md) | Open | — |
| 2026-09-14 | [Just-in-time delivery planner](2026-09-14-just-in-time-delivery-planner.md) | Open | — |
| 2026-09-03 | [Problem: iteration workflow timeout masks the actionable test failure](2026-09-03-iteration-workflow-timeout-masks-test-failure.md) | Open | — |
| 2026-06-21 | [Problem: Fabro-published commits are attributed to the GitHub user `fabro`](2026-06-21-fabro-commit-attribution.md) | Open | — |
| 2026-06-19 | [Problem: Gemini credit exhaustion broke Fabro review synthesis](2026-06-19-gemini-credit-exhaustion-breaks-review-workflow.md) | Experiment | 2026-10-19 |
| 2026-06-17 | [Problem: Handoff claimed `dev check` passed while current main fails in ExUnit](2026-06-17-dev-check-false-green-handoff.md) | Open | — |
| 2026-06-05 | [Problem: Fabro publish conflict left a manual merge to recover](2026-06-05-fabro-publish-conflict-leaves-manual-merge.md) | Open | — |
| 2026-06-04 | [Problem: Browser acceptance tests are slow, and shared global state blocks the parallelism that should speed them up](2026-06-04-acceptance-parallelization-blocked-by-global-state.md) | Open | — |
| 2026-06-04 | [Problem: Acceptance tests flake while waiting for projected member rows](2026-06-04-acceptance-projection-timing-flake.md) | Open | — |
| 2026-06-04 | [Problem: Domain Cucumber coverage is manual and incomplete](2026-06-04-domain-cucumber-coverage-is-manual-and-incomplete.md) | Open | — |
| 2026-05-30 | [Problem: Fabro implementation run required manual rescue after publish failure](2026-05-30-fabro-run-rescue-after-publish-failure.md) | Open | — |
| 2026-08-12 | [Problem: Fabro workflow model routing inferred the wrong provider after upgrade](2026-08-12-fabro-model-provider-inference-after-upgrade.md) | New | — |
| 2026-07-13 | [Problem: implementation timeout left only partial artifacts and weak diagnostics](2026-07-13-implementation-timeout-lacks-progress-diagnostics.md) | New | — |
| 2026-07-09 | [Problem: Feature-level `@not-ui` hides UI coverage gaps](2026-07-09-feature-level-not-ui-hides-ui-coverage-gap.md) | New | — |
| 2026-07-09 | [Problem: fresh sandbox Postgres role mismatch, and reset+seed against a reused Phoenix server poisons Commanded aggregates](2026-07-09-gallery-walk-stale-sandbox-postgres-role-and-aggregate-cache.md) | New | — |
| 2026-07-05 | [Problem: review repair loop repeated without a verified diff](2026-07-05-review-repair-loop-without-diff.md) | New | — |
| 2026-06-23 | [Problem: dev fabro progress exits before rendering when no tasks are complete](2026-06-23-dev-fabro-progress-zero-completed-exits.md) | New | — |
| 2026-06-18 | [Problem: implementation task-list check routed unchecked tasks to human failure](2026-06-18-implementation-task-list-check-routes-unchecked-tasks-to-human-failure.md) | New | — |
| 2026-06-09 | [Problem: Suggested slug autofill acceptance scenario is flaky](2026-06-17-slug-autofill-acceptance-flake.md) | New | — |
| 2026-06-17 | [Problem: Test command standard was not obvious during local implementation](2026-06-17-test-command-standard-not-obvious.md) | New | — |
| 2026-06-13 | [Problem: Feature-file creation and review are not reliably preserving exemplary Gherkin](2026-06-13-feature-file-quality-review-gap.md) | New | — |
| 2026-06-05 | [Problem: Onboarding email stream was not preflighted before production signup test](2026-06-05-onboarding-email-stream-not-preflighted.md) | New | — |
| 2026-06-04 | [Problem: dev check leaked real email provider configuration](2026-06-04-dev-check-leaked-real-email-env.md) | New | — |
| 2026-06-03 | [Problem: Fabro dev image CI does not refresh the Fabro host](2026-06-03-fabro-dev-image-ci-does-not-refresh-host.md) | New | — |
| 2026-06-02 | [Problem: Provider webhooks lacked authentication guardrails](2026-06-02-provider-webhook-authentication-gap.md) | New | — |
| 2026-06-01 | [Problem: Fabro marked iteration 016 merged while tasks were still incomplete](2026-06-01-fabro-iteration-016-premature-merge-and-zombie-runs.md) | New | — |
| 2026-09-20 | [Problem: iteration review repair left a detached dev check running into the workflow gate](2026-09-20-iteration-review-detached-dev-check-stall.md) | Closed | — |
| 2026-09-13 | [Problem: task validator requested a retry, but the workflow terminated](2026-09-13-task-retry-verdict-terminates-iteration.md) | Closed | — |
| 2026-09-12 | [Problem: Acceptance inputs raced LiveView root join](2026-09-12-acceptance-inputs-race-liveview-join.md) | Closed | — |
| 2026-09-12 | [Problem: dev check can validate the wrong checkout](2026-09-12-dev-check-can-validate-the-wrong-checkout.md) | Closed | — |
| 2026-09-05 | [Problem: dev ci masked a failing precommit behind passing browser acceptance](2026-09-05-dev-ci-masked-precommit-failure.md) | Closed | — |
| 2026-09-05 | [Problem: recovered iteration workflow launched from the wrong checkout](2026-09-05-fabro-recovery-launched-from-wrong-checkout.md) | Closed | — |
| 2026-09-05 | [Problem: review repair evidence ignored staged changes](2026-09-05-review-repair-evidence-ignored-staged-changes.md) | Closed | — |
| 2026-09-04 | [Problem: Fabro model routing lacked an explicit cost and independence policy](2026-09-04-fabro-model-routing-lacked-cost-and-role-policy.md) | Closed | — |
| 2026-09-04 | [Problem: implementation todo generator created tasks from prerequisites and scope guards](2026-09-04-implementation-todo-generator-created-scope-guard-tasks.md) | Closed | — |
| 2026-09-04 | [Problem: implementation workflow final artifact failure could route to publish under Fabro terminal-success semantics](2026-09-04-implementation-workflow-terminal-success-gate.md) | Closed | — |
| 2026-09-04 | [Improvement: iteration-review can safely fan out and fan in reviewer evidence again](2026-09-04-iteration-review-parallel-fan-in-restored.md) | Closed | — |
| 2026-06-23 | [Problem: coarse Fabro todos exhausted an implementation node timeout](2026-06-23-coarse-fabro-todos-timeout.md) | Closed | — |
| 2026-06-23 | [Problem: bin/dev fabro deliver stream timeout leaves remote run state ambiguous](2026-06-23-fabro-deliver-stream-timeout-ambiguous.md) | Closed | — |
| 2026-06-23 | [Problem: Fabro focused tests can use stale PGHOST and fail despite Postgres being ready](2026-06-23-fabro-focused-tests-stale-pghost.md) | Closed | — |
| 2026-06-23 | [Problem: Fabro read-guard can block routine todo.md check-off late in a task](2026-06-23-fabro-read-guard-todo-checkoff-friction.md) | Closed | — |
| 2026-06-23 | [Problem: Fabro sandbox files can be root-owned and block formatting](2026-06-23-fabro-sandbox-root-owned-files-block-format.md) | Closed | — |
| 2026-06-18 | [Problem: Domain architecture guidance was implicit and not visible enough to reviewers](2026-06-18-domain-pattern-reference-guidance.md) | Closed | — |
| 2026-06-09 | [Problem: Iteration review accepted despite failing to record code-health findings](2026-06-09-iteration-review-code-health-recording-failure.md) | Closed | — |
| 2026-06-06 | [Problem: implementation workflow left completed iteration marked implementing](2026-06-06-implementation-workflow-does-not-mark-merged.md) | Closed | — |
| 2026-06-06 | [Problem: Planning skill does not validate plans by default](2026-06-06-planning-skill-does-not-validate-plan-by-default.md) | Closed | — |
| 2026-06-05 | [Plan: Continue acceptance fast-feedback improvements without sharding](2026-06-05-acceptance-fast-feedback-follow-up-plan.md) | Closed | — |
| 2026-06-05 | [Problem: IterationReview dev check cannot find cucumber-js](2026-06-05-iteration-review-missing-cucumber-js.md) | Closed | — |
| 2026-06-05 | [Problem: Plan validation failed because chunked plan reads were still summarized](2026-06-05-plan-validation-chunked-read-still-summarized.md) | Closed | — |
| 2026-06-04 | [Problem: Concurrent `dev check` runs race over shared test resources](2026-06-04-dev-check-concurrent-runs-race.md) | Closed | — |
| 2026-06-03 | [Problem: Fabro implementation loop wedged the remote server after rate limits](2026-06-03-fabro-rate-limit-loop-wedges-server.md) | Closed | — |
| 2026-06-03 | [Problem: Inbound email release lacks an end-to-end smoke-test spec](2026-06-03-inbound-email-smoke-tests-missing-from-release-handoff.md) | Closed | — |
| 2026-06-02 | [Problem: Fabro outage forced local iteration fallback](2026-06-02-fabro-outage-forced-local-iteration-fallback.md) | Closed | — |
| 2026-06-01 | [Problem: acceptance lifecycle calls removed `dev postgres` subcommand](2026-06-01-acceptance-lifecycle-calls-removed-dev-postgres.md) | Closed | — |
| 2026-06-01 | [Problem: Plan validation failed because reviewers saw truncated plan text](2026-06-01-plan-validation-truncated-read-false-negative.md) | Closed | — |
| 2026-06-01 | [Problem: Plan validation depends on unsupported Codex model](2026-06-01-plan-validation-unsupported-codex-model.md) | Closed | — |
| 2026-06-01 | [Problem: prod auth token table drift caused sign-in 500](2026-06-01-prod-auth-token-table-schema-drift.md) | Closed | — |
| 2026-05-31 | [Problem: Auth iteration planning missed BDD scenarios](2026-05-31-auth-iteration-missed-bdd-scenarios.md) | Closed | — |
| 2026-05-31 | [Problem: deliver allows iterations to start out of order](2026-05-31-deliver-allows-out-of-order-iterations.md) | Closed | — |
| 2026-05-31 | [Problem: failed deliver leaves stale implementing status](2026-05-31-deliver-leaves-stale-implementing-status.md) | Closed | — |
| 2026-05-31 | [Problem: `dev check` cannot run beside `dev up`](2026-05-31-dev-check-cannot-run-beside-dev-up.md) | Closed | — |
| 2026-05-31 | [Problem: implementation workflow publish depends on missing sandbox Python](2026-05-31-iteration-implementation-python3-publish-failure.md) | Closed | — |
| 2026-05-31 | [Problem: Review synthesis LLM outage failed an otherwise recoverable iteration review](2026-05-31-review-synthesis-llm-outage-fails-run.md) | Closed | — |
| 2026-05-30 | [Problem: deliver command should handle validated plans and WIP waiting explicitly](2026-05-30-deliver-validated-plan-wip-waiting.md) | Closed | — |
| 2026-05-30 | [Problem: Iteration deliver stalled waiting for child-run approval](2026-05-30-iteration-deliver-child-approval-stall.md) | Closed | — |
| 2026-05-30 | [Problem: iteration implementation hit reset-task retry cycle limit](2026-05-30-iteration-implementation-reset-cycle-limit.md) | Closed | — |
| 2026-05-30 | [Problem: Validate-only wrapper cannot start its validation child unattended](2026-05-30-iteration-validate-wrapper-child-approval.md) | Closed | — |
| 2026-05-30 | [Plan: carve out browser Cucumber automation iteration](2026-05-30-plan-browser-cucumber-automation.md) | Closed | — |
| 2026-05-30 | [Problem: plan-validation parallel fan-in does not expose reviewer evidence to synthesis](2026-05-30-plan-validation-parallel-fan-in-evidence-gap.md) | Closed | — |
| 2026-05-30 | [Plan: review salvaged iteration 005](2026-05-30-review-salvaged-005.md) | Closed | — |
| 2026-05-30 | [Problem: Review workflow accepted code but still failed during finalization](2026-05-30-review-workflow-accepted-code-but-finalization-failed.md) | Closed | — |
| 2026-05-30 | [Plan: salvage iteration 005 app slice](2026-05-30-salvage-005-app-slice.md) | Closed | — |
| 2026-05-30 | [Plan: simplify Fabro delivery orchestration](2026-05-30-simplify-fabro-delivery-orchestration.md) | Closed | — |
| 2026-05-29 | [Problem: checkpoint exclude globs did not prevent ignored .fabro/tmp add](2026-05-29-checkpoint-exclude-globs-did-not-cover-ignored-tmp.md) | Closed | — |
| 2026-05-29 | [Kaizen: commit_task must tolerate checkpointed task work](2026-05-29-commit-task-after-checkpointed-task-work.md) | Closed | — |
| 2026-05-29 | [Kaizen: deliver iterations by merging to main, drop PRs](2026-05-29-deliver-iterations-by-merging-to-main.md) | Closed | — |
| 2026-05-29 | [Problem: Fabro checkpoint tried to add ignored .fabro/tmp](2026-05-29-fabro-checkpoint-adds-ignored-tmp.md) | Closed | — |
| 2026-05-29 | [Problem: Iteration 003 review accepted implementation but publish polish rebase failed](2026-05-29-iteration-003-review-polish-rebase-conflict.md) | Closed | — |
| 2026-05-29 | [Kaizen: nest validate→implement→review into one iteration-deliver workflow](2026-05-29-iteration-deliver-workflow.md) | Closed | — |
| 2026-05-29 | [Idea: keep iterations small by sizing and slicing during planning](2026-05-29-iteration-lifecycle-and-slicing.md) | Closed | — |
| 2026-05-29 | [Kaizen: iteration review evidence collection can fail silently before diagnostics](2026-05-29-iteration-review-evidence-script-silent-exit.md) | Closed | — |
| 2026-05-29 | [Kaizen: iteration review cannot reliably collect evidence from Fabro run branches](2026-05-29-iteration-review-run-branch-evidence-collection.md) | Closed | — |
| 2026-05-29 | [Problem: iteration review sandbox clone timed out](2026-05-29-iteration-review-sandbox-clone-timeout.md) | Closed | — |
| 2026-05-29 | [Kaizen: mark iterations merged in the index](2026-05-29-mark-iterations-merged-in-index.md) | Closed | — |
| 2026-05-29 | [Kaizen: move plan conformance into the implementation workflow](2026-05-29-move-plan-conformance-to-implementation.md) | Closed | — |
| 2026-05-29 | [Kaizen: allow plan review ahead of implementation while enforcing implementation WIP limit](2026-05-29-plan-review-before-implementation-wip-limit.md) | Closed | — |
| 2026-05-29 | [Problem: plan-validation synthesis dropped independent reviewer findings](2026-05-29-plan-validation-synthesis-dropped-review-findings.md) | Closed | — |
| 2026-05-29 | [Kaizen: PR creation should not depend on the wrong LLM](2026-05-29-pr-creation-should-not-depend-on-llm.md) | Closed | — |
| 2026-05-29 | [Kaizen: resumability needs an accessible branch, not just task commits](2026-05-29-resume-contract-gap-between-checkpoints-and-branches.md) | Closed | — |
| 2026-05-29 | [Plan: return iteration implementation to Fabro-managed clone and run branches](2026-05-29-return-to-fabro-managed-clone-for-resumability.md) | Closed | — |
| 2026-05-29 | [Problem: Iteration review checkpoint tried to add ignored .fabro/tmp](2026-05-29-review-checkpoint-adds-ignored-tmp.md) | Closed | — |
| 2026-05-29 | [Problem: Iteration review publish checkpoint used stale tmp ignore from review branch](2026-05-29-review-publish-used-stale-tmp-ignore.md) | Closed | — |
| 2026-05-29 | [Problem: Iteration review sandbox clone failed with no space left on device](2026-05-29-review-sandbox-clone-no-space.md) | Closed | — |
| 2026-05-28 | [Plan: stop the blind validator from hallucinating a persistence failure and resetting good work](2026-05-28-blind-validator-false-reset.md) | Closed | — |
| 2026-05-28 | [Kaizen: validator fix confirmed; long runs die opaquely when Anthropic credits run out](2026-05-28-credit-exhaustion-mid-run.md) | Closed | — |
| 2026-05-28 | [Idea: extract review/repair tail into a separate iteration-review workflow](2026-05-28-extract-iteration-review-workflow.md) | Closed | — |
| 2026-05-28 | [Idea: make iteration-implementation resumable across runs](2026-05-28-resumable-iteration-implementation.md) | Closed | — |
| 2026-05-28 | [Idea: simplify iteration task loop ownership](2026-05-28-simplify-iteration-task-loop.md) | Closed | — |
| 2026-05-28 | [Idea: task contract validation for iteration workflow](2026-05-28-task-contract-validation-workflow.md) | Closed | — |
| 2026-05-28 | [Idea: task-draining iteration implementation workflow](2026-05-28-task-draining-iteration-workflow.md) | Closed | — |
| 2026-05-27 | [Plan: ADR-aware iteration implementation harness](2026-05-27-iteration-implementation-adr-gate-plan.md) | Closed | — |
| 2026-05-27 | [Plan: harden iteration implementation workflow beyond ADR gate](2026-05-27-iteration-implementation-hardening-plan.md) | Closed | — |
