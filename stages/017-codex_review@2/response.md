# Review Report

## Decision: ACCEPT

## Confidence: Medium

The implementation appears plan-conforming and narrowly scoped to Fabro workflow infrastructure plus the kaizen note. Confidence is not High because the running review workflow continued using the old inline evidence-collection script after the mid-run repair, so direct excerpts of the changed `.fabro/` files were still not available from the collected evidence.

## ADR conformance: PASS

No ADRs were cited by the plan, and the changed files are limited to:

- `.fabro/workflows/iteration-review/*`
- `docs/kaizen/2026-06-09-iteration-review-code-health-recording-failure.md`

No product architecture, Phoenix/LiveView structure, persistence, eventing, routing, or infrastructure governed by ADRs appears to have been changed.

## ADR violations

None identified.

## Blocking issues

None identified.

The implementation fixes the core failure mode described in the plan: `record_code_health` is no longer a prompt-only node that can report failure without affecting routing, and the workflow now has an explicit failed-recording terminal path.

## Bounded-safe fixes

1. **Harden the review-repair verification script against missing comparison tools**

   - **Files:** likely `.fabro/workflows/iteration-review/workflow.fabro` or the workflow script backing `verify_review_repair`
   - **Issue:** The `verify_review_repair` stage printed:

     ```text
     /bin/bash: line 13: cmp: command not found
     ```

     but the stage still succeeded because the missing `cmp` command was inside an `if cmp -s ...` conditional. That means the “repair produced no diff” guard can silently fail open in sandboxes without `cmp`.
   - **Suggested safe fix:** Replace the `cmp -s "$before" "$after"` check with a comparison mechanism available in the project’s expected runtime, or explicitly check command availability before using it. For example:

     ```sh
     if git diff --no-index --quiet "$before" "$after"; then
       echo "${kind} repair produced no working-tree diff change since repair started." >&2
       exit 1
     fi
     ```

     or use a checked `sha256sum`/`diff` fallback. Add a small guard test if this verification logic is script-backed.

## Judgement-worthy non-blocking code-health findings

1. **Code-health recording success still relies on agent self-reporting**

   - **Files:** `.fabro/workflows/iteration-review/workflow.fabro`, `.fabro/workflows/iteration-review/prompts/record_code_health.md`
   - **Smell:** The workflow now routes based on `context.code_health_recording_ok=true/false` emitted by the `record_code_health` agent. This is much better than the previous unconditional route, but it still trusts the agent to accurately report that durable recording happened.
   - **Why it may need human judgement:** The original issue was a trust failure in the review workflow. A deterministic postcondition gate — for example, checking that `docs/code-health.md` changed when judgement-worthy findings exist, or that an alternative durable artifact was created — would provide stronger assurance than prompt-contract self-reporting. This does not block the current fix because the previous failure signal is no longer ignored.

2. **Recorder path has not yet been exercised with real judgement-worthy findings**

   - **Files:** `.fabro/workflows/iteration-review/workflow.fabro`, `.fabro/workflows/iteration-review/prompts/record_code_health.md`
   - **Smell:** Static guard tests and workflow validation support the new routing, but the plan still records a follow-up: a future real review run should confirm that the agent node can actually append to `docs/code-health.md` when findings are present.
   - **Why it may need human judgement:** For internal workflow infrastructure, static routing guards may be sufficient for an incremental fix. For a final review quality gate, humans may prefer a synthetic integration test covering “findings present → durable record created → success route.”

3. **Mid-run workflow repairs did not affect the currently executing workflow instance**

   - **Files:** `.fabro/workflows/iteration-review/workflow.fabro`, `.fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh`
   - **Smell:** The evidence collector was reportedly repaired to include `.fabro/workflows/` and `docs/kaizen/`, but the subsequent `collect_implementation_evidence` stage still ran the old inline script and reported:

     ```text
     No changed files matched the excerpt filter.
     ```

   - **Why it may need human judgement:** This appears to be Fabro workflow execution-model behavior rather than an implementation defect: the running instance did not reload the updated workflow definition. It weakens review visibility in this run but should be corrected for future runs if the workflow now calls the extracted script. Humans may want to clarify/document whether mid-run workflow definition changes are expected to take effect.

4. **Previously observed browser acceptance instability remains a project signal**

   - **Files:** `features/staff_club_slugs.feature` / browser acceptance support, not changed by this implementation
   - **Smell:** The kaizen note records an earlier intermittent failure in `Staff create a club with the suggested slug`, where `#club-slug-input` remained empty. The scenario passed in the review `dev ci` run.
   - **Why it may need human judgement:** This implementation did not touch that product path, so it should not block this workflow fix. If the instability recurs, it should be tracked separately because flaky acceptance tests reduce trust in the delivery pipeline.

## Suggested fixes

For the bounded-safe issue:

1. Update the repair verification comparison logic so a missing comparison command cannot cause the guard to silently pass.
2. Prefer `git diff --no-index --quiet`, `diff -q`, or a checked hash-based comparison over an unchecked `cmp`.
3. Add a focused shell test if the verification logic is extracted or already script-backed.

Optional future improvements:

- Add a deterministic post-recording gate for `docs/code-health.md` or an equivalent durable artifact.
- Add a synthetic test for the “judgement-worthy findings present” recording path.
- Document Fabro’s workflow-definition reload semantics for mid-run repairs.

## Validation notes

Relevant validation signals:

- Preflight sandbox check passed.
- `dev ci` passed.
- Browser acceptance passed: `77 scenarios`, `502 steps`.
- The previously flaky `Staff create a club with the suggested slug` scenario passed during review.
- Changed files are limited to Fabro workflow infrastructure and the kaizen note.
- Acceptance feature files were not changed.
- Reported implementation validation included:
  - `test_review_report_routing.sh` passing.
  - `test_collect_implementation_evidence.sh` passing.
  - `dev check --quick` passing.
  - `git diff --check` passing.

Validation caveats:

- The current running review workflow still used the old evidence collector, so direct file excerpts of the changed `.fabro/` files were not available in the collected evidence.
- `verify_review_repair` emitted `cmp: command not found` while still succeeding, indicating one workflow guard can currently fail open.