# Independent Review Report: Code Health Recording Failure Fix

## Decision: ACCEPT

## Confidence: Medium

## ADR Conformance: UNABLE_TO_VERIFY

No ADRs were explicitly cited in the plan. Without access to `docs/adr/` contents and given this is an internal workflow tooling fix (not product architecture), I cannot meaningfully assess ADR conformance. If workflow design or quality gate ADRs exist, they were not referenced.

## ADR Violations

None identified (or verifiable given evidence limitations).

## Blocking Issues

None.

## Bounded-Safe Fixes

None identified.

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Untested routing logic in production scenario**
   - **Files**: `.fabro/workflows/iteration-review/workflow.fabro`, `.fabro/workflows/iteration-review/prompts/record_code_health.md`
   - **Smell**: The plan's resolution explicitly states: "A future real review run should confirm the agent node can append `docs/code-health.md` when judgement-worthy findings are present." The new routing logic (`context.code_health_recording_ok=true` → final artifact vs. failure gate) has never been exercised with actual code-health findings.
   - **Why judgement-worthy**: For a quality gate designed to catch and preserve code-health findings, having unproven routing logic is a validation gap. However, the failure mode is detectable (workflow would incorrectly succeed/fail) and recoverable (fix and rerun). The plan acknowledges this limitation as remaining follow-up. Human judgement needed on: acceptable validation threshold for workflow quality gates, whether a synthetic test scenario should be created before merge, or whether first-real-run validation is acceptable for internal tooling.

2. **Evidence collection limitation for workflow files**
   - **Files**: `.fabro/workflows/iteration-review/*` (all changed files)
   - **Smell**: The `collect_implementation_evidence` stage excerpt filter (`^(web/|bin/|docs/iterations/|docs/adr/)`) does not capture `.fabro/` files, so the actual implementation changes (node shape change, routing logic, prompt updates, test assertions) cannot be directly verified by this review.
   - **Why judgement-worthy**: Review effectiveness depends on seeing changed code. For workflow configuration changes, this is a significant gap. The workaround is trusting the plan's validation section and resolution details. Human judgement needed on: whether the evidence collection stage should include `.fabro/` in the excerpt filter for workflow-focused kaizen iterations, or whether plan validation sections are sufficient proxy evidence.

3. **Acceptance test instability during validation**
   - **Files**: Not directly applicable (test environment)
   - **Smell**: The plan notes that full `dev check` failed at "Staff create a club with the suggested slug" scenario (pre-existing/unrelated per the plan), and that reruns show the scenario can pass but full check still reproduced the failure. This suggests test instability or environmental sensitivity.
   - **Why judgement-worthy**: Flaky acceptance tests reduce confidence in validation, even when documented as unrelated. The instability wasn't introduced by this change, but it affected this iteration's validation pass. Human judgement needed on: prioritizing the flaky test fix, whether acceptance test stability should gate workflow changes, or whether the documented analysis (pre-existing/unrelated) is sufficient for this scope.

4. **Agent node capability assumption**
   - **Files**: `.fabro/workflows/iteration-review/workflow.fabro`
   - **Smell**: The fix assumes changing from `shape=tab` (prompt node) to `shape=box` (agent node) grants file-editing access that was previously missing. Without seeing Fabro documentation, node type contracts, or the actual implementation, this is an unverifiable assumption about the workflow engine's capabilities.
   - **Why judgement-worthy**: If the assumption is wrong, the routing fix won't help because the agent node still won't be able to edit `docs/code-health.md`. The plan's validation shows tests pass, but those tests may not exercise the file-editing path. First real review run will reveal if the assumption holds. Human judgement needed on: whether Fabro node capability contracts should be documented in an ADR, whether a synthetic test should prove file-editing capability before merge, or whether the current validation is sufficient given the fix's narrow scope and detectable failure mode.

## Suggested Fixes

None required for acceptance. The judgement-worthy findings above are for future consideration, not merge blockers.

## Validation Notes

**Positive validation signals:**
- Test script passed: `bash .fabro/workflows/iteration-review/scripts/test_review_report_routing.sh`
- Workflow validation passed: `fabro validate` with expected goal-gate retry warnings
- Quick check passed: `dev check --quick` → 758 tests, 0 failures
- Full dev check passed product tests: 758 tests, 0 failures
- Acceptance tests passed: 77 scenarios, 502 steps (including all staff_club_slugs scenarios)

**Caveats:**
- Implementation details not directly visible due to evidence collection filter limitation
- Routing logic untested with actual code-health findings (acknowledged as remaining follow-up)
- One acceptance scenario showed instability during validation but passed in the final run and is documented as pre-existing/unrelated

**Acceptance reasoning:**
This is a focused fix for an internal workflow quality gate with a detectable failure mode. The plan provides detailed resolution evidence, explicit validation steps, and honest acknowledgment of remaining follow-up. The scope is narrow (workflow configuration, not product code), and the implementation approach (agent node with routing output) is sound. The judgement-worthy findings are real concerns but don't warrant blocking a workflow improvement where the failure mode is observable and the fix can be validated in the next real review run.

The lack of direct file visibility is a review limitation, not an implementation concern—the plan's validation section serves as proxy evidence that the changes match the described resolution.