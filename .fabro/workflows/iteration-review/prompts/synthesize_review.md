Synthesize the independent implementation reviews for {{ inputs.plan_path }}.

This review runs after implementation has already merged to `main`. It is a smell radar and bounded polish loop, not a delivery gate. Decide whether there are bounded fixes the workflow should attempt now, or whether remaining findings should be logged for human judgement in `docs/code-health.md` while the run continues.

## Context

Use the prior context from this workflow run:

- The iteration plan text and its explicit requirements.
- Implementation evidence collected from `{{ inputs.base_sha }}` to `HEAD`.
- Successful `dev check` output.
- The merged parallel fan-in evidence in `parallel.results` from the Claude Review (`claude_review`), Sol Review (`codex_review`), and Gemini Review (`gemini_review`) branches.
- Previous synthesis decisions and repair summaries, if this is a repeated synthesis after repair.

The reviewer stages fan out independently and then fan in before this stage. In the merged context, inspect `parallel.results` explicitly. Each required branch must expose a completed outcome and the substantive Markdown response for that reviewer. Do not assume branch responses or routing fields are promoted to top-level context.

Fail closed if you cannot see usable, substantive reviewer evidence for all three required branches in `parallel.results`. Branch status metadata, head SHAs, empty strings, or tool-call-looking JSON without an actual review report are not usable reviewer evidence. Missing reviewer evidence is a workflow/tooling failure, not proof that the implementation is acceptable and not a product-code fix.

If any required reviewer evidence is missing or unusable, do not route **ACCEPTED** and do not route **FIX**. Return an infrastructure-failure synthesis that names the missing/unusable branch evidence and end with routing JSON that sets the stage outcome to failed, for example: `{"outcome":"failed","failure_reason":"parallel fan-in did not expose usable review evidence for every required reviewer"}`. This must route to the workflow's review-synthesis-unavailable failure path.

Do not emit shell-command/tool-call JSON; return the Markdown synthesis and final routing JSON only.

## Standards

- Treat accepted ADRs as binding. Use `docs/reference/domain-driven-design.md`, `docs/reference/cqrs.md`, `docs/reference/event-sourcing.md`, and `docs/reference/responsibility-driven-design.md` as the design-quality guidelines for domain modeling, Commanded/CQRS, event streams/projections, aggregates, and responsibility/collaboration boundaries. They guide interpretation of ADRs and code-health findings; they do not override an accepted ADR or iteration plan.
- Treat automated tests and implementation plan-conformance as already-owned by the implementation workflow.
- Prefer automatic improvement over deferral. Request automatic fixes for every concrete, bounded refactoring, maintainability, project-convention, documentation, security-hardening, data-integrity-hardening, or low-risk test-quality issue that can be resolved without changing acceptance feature files or making a new product decision.
- Verification findings are often auto-fixable: if reviewers are unsure whether an implemented rule is truly wired, reused, or protected, route **FIX** when the workflow can add/strengthen targeted automated tests, assertions, constraints, or code comments to prove the existing intended behaviour.
- Examples of normally bounded automatic fixes: normalizing inputs before duplicate checks, adding HTML form attributes that match existing validation, adding double-submit protection where the project has an established pattern, adding/strengthening domain/web tests for planned behaviour, adding database constraints that enforce an already-existing invariant, replacing duplicated implementation with an existing shared service, and documenting a non-obvious shared path in code.
- Do not request edits to acceptance feature files (`*.feature`).
- Do not introduce new product behaviour in review; hardening is allowed when it enforces or proves behaviour already required by the iteration plan.
- Mark a finding as code-health/manual only when it needs external/manual verification that cannot be represented by an automated test, requires a product/architecture/scope decision, is too large or risky for the review repair budget, or a prior automatic repair attempted the same issue and it still remains.
- If any reviewer lists judgement-worthy non-blocking code-health findings, preserve them in the `Code-health findings for human judgement` section even when the final decision is **ACCEPTED**.
- If any reviewer lists bounded-safe fixes or hardening ideas, either route **FIX** with exact bounded changes, or explicitly explain why each proposed fix is not auto-fixable under these rules. Do not silently defer useful hardening.
- If no bounded automatic fixes are worth attempting, accept the review and let the next step record any judgement-worthy findings in `docs/code-health.md`.

## Output format

Return a concise Markdown synthesis with these sections:

### Decision

One of: **ACCEPTED**, **FIX**, or **INFRASTRUCTURE FAILURE**. Use **INFRASTRUCTURE FAILURE** only when the required reviewer evidence in `parallel.results` is missing or unusable.

### Evidence preflight

List Claude Review, Sol Review, and Gemini Review. For each, state whether usable substantive evidence was present in `parallel.results`. If any are missing or unusable, stop the synthesis after this section and route the stage outcome to failed.

### Review synthesis

Summarize the important findings across reviewers.

### Finding disposition

Account for each substantive reviewer finding as one of: auto-fix now, record for human judgement, dismissed as unsupported, duplicate/already fixed.

### Bounded automatic fixes

If **FIX**, list exact bounded changes to make, with constraints and validation. Include test/constraint/documentation-only fixes when they are the safest way to make an uncertainty visible and enforceable.

### Code-health findings for human judgement

List findings that should be logged to `docs/code-health.md` because they are not safe bounded review fixes. If none, state "None."

### Fixed or dismissed findings

Note findings that were already fixed during this review run, duplicates, or findings you are dismissing as not supported by evidence.

## Routing JSON

End your response with exactly one JSON object that Fabro can use for routing. The JSON object must be the final text in the response and must not be wrapped in a Markdown code fence.

Use one of these shapes:

- Accepted / log-only findings:
  `{"context_updates":{"implementation_accepted":true,"review_fixes_available":false}}`
- Automatic fixes appropriate:
  `{"context_updates":{"implementation_accepted":false,"review_fixes_available":true,"review_blockers":[{"id":"fix-id-1","title":"Short fix title","source":"review_synthesis","first_seen_stage":"synthesize_review","status":"open"}]}}`
- Infrastructure/tooling failure because required merged review evidence is missing or unusable:
  `{"outcome":"failed","failure_reason":"parallel fan-in did not expose usable review evidence for every required reviewer"}`

Do not route to human input from this post-merge review. Human-judgement findings belong in the Markdown section above so the next step can record them in `docs/code-health.md`.
