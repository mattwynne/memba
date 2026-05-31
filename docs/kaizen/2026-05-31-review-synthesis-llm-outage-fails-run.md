# Problem: Review synthesis LLM outage failed an otherwise recoverable iteration review

Date: 2026-05-31

## Context

We were checking whether the Fabro iteration review for iteration 010 was complete.

Relevant run:

- Fabro run: `01KSZZBQ0M243VTDR0VSZC0QR4`
- Workflow: `iteration-review`
- Plan: `docs/iterations/010-shared-magic-link-auth/plan.md`
- Goal: "Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals"

## Expected standard

The iteration review workflow should be resilient enough that a transient LLM/provider failure in a late synthesis step does not erase or obscure earlier useful review evidence. If independent reviews have completed and `dev check` passes, the workflow should either retry the synthesis, preserve a clear resumable state, or route to a specific recoverable/manual synthesis path.

## What happened

The run made substantial progress:

- Initial `dev check` failed on `MembaWeb.Plugs.CanonicalHostRedirectTest` because `/admin/clubs` now correctly redirects unauthenticated users to `/auth` after iteration 010 protected admin routes.
- The review workflow's fix stage updated the test to authenticate as staff.
- `dev check` then passed.
- `dev ci` also passed.
- The independent Claude, Codex, and Gemini review branches completed successfully.

The workflow then failed at `Synthesize Review` with an upstream OpenAI connection failure:

```text
LLM error: Server error from openai: upstream connect error or disconnect/reset before headers. retried and the latest reset reason: remote connection failure, transport failure reason: delayed connect error: Connection refused
```

Because synthesis failed, the review gate took the default `Needs human input` path and the run ended failed:

```text
Iteration review failed: reviewers found blocking issues that require human input or exceeded the automatic repair budget.
```

The final status was:

```text
failed/workflow_error
```

This status was misleading: the observed hard failure was the synthesis model call, not confirmed reviewer-blocking product findings.

## Impact

This created avoidable manual archaeology. We had to inspect `fabro events` and `fabro logs` to distinguish product review failure from delivery-machinery failure. It also made it harder to confidently mark the iteration done even though the code had already passed `dev check`/`dev ci` and the user was doing a manual review.

Severity: repeated workflow friction / quality-risk signal. It can cause good iteration work to appear failed and may hide useful independent review evidence behind a terminal workflow failure.

## What allowed it to happen

The review workflow appears to have weak resilience and classification around late LLM synthesis failures:

- No successful retry or fallback model/provider path protected the synthesis step.
- The gate treated missing synthesis as `Needs human input`, which conflated infrastructure failure with reviewer findings.
- The final failure message said reviewers found blocking issues or repair budget was exceeded, but the logged root cause was an OpenAI connection refusal.
- The workflow did not surface an obvious "synthesis failed, independent review artifacts are available" recovery path in the terminal status.

## Observations

- `fabro ps` showed no active runs; this was a terminal failed run.
- `fabro logs 01KSZZBQ0M243VTDR0VSZC0QR4 --tail 300` showed the specific OpenAI connection refusal at `Synthesize Review`.
- `fabro events 01KSZZBQ0M243VTDR0VSZC0QR4 --pretty --tail 200` showed the independent review branches completed before the failure.
- The workflow had already repaired the deterministic test failure and verified `dev check` and `dev ci`.
- The terminal failure wording did not preserve the distinction between provider outage and review rejection.

## Why this matters

Late-stage synthesis is a summarisation/reduction step, not the only source of truth. If it fails transiently, future runs may waste time redoing implementation or reviews, and operators may misinterpret infrastructure failures as product-quality failures.

## Open questions

- Are Fabro prompt nodes configured with enough retry attempts for transient provider/network failures?
- Can `iteration-review` route synthesis failures to a manual summary or fallback provider without marking reviewer findings as blocking?
- Where are independent review artifacts stored, and can the terminal output link to them when synthesis fails?
- Should the workflow distinguish `review_blocked`, `infra_failed`, and `needs_manual_synthesis` outcomes?

## Possible prevention ideas

- Add retries with backoff around `Synthesize Review`.
- Add fallback model/provider configuration for synthesis.
- Route synthesis provider failures to a separate `Needs manual synthesis` path with a clear message and artifact locations.
- Preserve and surface independent review artifacts even when synthesis fails.
- Change terminal copy so provider failures do not say reviewers found blocking issues.
