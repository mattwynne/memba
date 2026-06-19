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
