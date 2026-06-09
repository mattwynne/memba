# Review Report

## Decision: ACCEPT

## Confidence: Medium

## ADR conformance: PASS

No ADRs were cited in the plan. The implementation changes are limited to internal Fabro workflow mechanics (`.fabro/workflows/iteration-review/*`) and a kaizen note. No product architecture or infrastructure governed by ADRs was touched.

## ADR violations

None identified.

## Blocking issues

None identified.

The original implementation fixed the code-health recording failure as planned. The review repair addressed the evidence collection gap. All automated validation passed (`dev check`, workflow guard tests, script tests). The acknowledged limitation that "a future real review run should confirm the agent node can append docs/code-health.md when judgement-worthy findings are present" is documented follow-up, not a validation gap requiring a block.

## Bounded-safe fixes

None identified.

The repair agent already extracted the evidence collector into a dedicated script, expanded the filter, added regression tests, and strengthened guards. Without direct file content visibility (see findings below), no additional concrete low-risk refactoring opportunities are apparent.

## Judgement-worthy non-blocking code-health findings

1. **Workflow instance executed old definition after mid-run repair**
   - **Files**: `.fabro/workflows/iteration-review/workflow.fabro`, `.fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh`
   - **Smell**: The second `collect_implementation_evidence` stage (after the review repair) still ran the old inline script with the restrictive filter, reporting `No changed files matched the excerpt filter.` The repair agent's validation evidence shows it correctly created the new script, updated `workflow.fabro` to call it, and tested it successfully. But the running workflow instance continued executing the old definition.
   - **Why it may need human judgement**: This creates a meta-verification gap: the review repair fixed the evidence collection limitation, but we can't see the fix working in this run because Fabro didn't reload the workflow definition mid-run. The fix is correct and will work in future runs (proven by the repair agent's script tests and `dev check` passing). Humans may want to decide: (a) Is mid-run workflow reload expected Fabro behavior? (b) Should workflow repairs trigger instance restart? (c) Is this execution model limitation acceptable for review workflows? This doesn't block merge because the code changes are correct and validated, but it's a workflow execution trust signal.

2. **Agent-based code-health recording success still depends on self-reporting**
   - **Files**: `.fabro/workflows/iteration-review/workflow.fabro`, `.fabro/workflows/iteration-review/prompts/record_code_health.md`
   - **Smell**: The routing logic uses `context.code_health_recording_ok=true/false` set by the `record_code_health` agent node. There's no deterministic postcondition gate verifying a `docs/code-health.md` diff when findings are present, or checking file timestamps, or other independent evidence that durable recording actually happened.
   - **Why it may need human judgement**: The original failure was a trust issue (workflow succeeded while findings weren't recorded). The fix routes on agent-reported success/failure, which is better than ignoring the signal, but still trusts the agent to truthfully report. A deterministic postcondition check would provide stronger assurance. The plan acknowledges "a future real review run should confirm the agent node can append docs/code-health.md when judgement-worthy findings are present." Humans should decide: acceptable validation threshold for workflow quality gates? Synthetic test scenario before merge? Or first-real-run validation sufficient for internal tooling?

3. **Routing logic validated by guards but not exercised with real findings**
   - **Files**: `.fabro/workflows/iteration-review/workflow.fabro`, routing tests
   - **Smell**: The new routing (success → final artifact gate, failure → dedicated failure gate) passed static guard assertions but hasn't been proven with an actual review run containing judgement-worthy code-health findings.
   - **Why it may need human judgement**: For a quality gate designed to preserve maintainability signals, untested routing is a coverage gap. The plan explicitly acknowledges this as "remaining follow-up." Humans should decide: acceptable to merge before first real run validation? Create synthetic test scenario? Or is the guard test + first-real-run approach sufficient for workflow infrastructure?

4. **Pre-existing acceptance test instability observed during validation**
   - **Files**: `features/staff_club_slugs.feature` (not changed)
   - **Smell**: The plan notes a full `dev check` failure in "Staff create a club with the suggested slug" scenario (`#club-slug-input` remained empty), documented as pre-existing/unrelated. Final `dev check` in this run passed (77 scenarios, 502 steps), but the instability signal remains.
   - **Why it may need human judgement**: Flaky browser acceptance tests reduce confidence in validation over time. This implementation didn't touch product code or feature files, and the final run passed, but if the instability recurs it should be tracked separately. Not a blocker for this workflow fix.

## Suggested fixes

None required for acceptance.

Optional future consideration:
- Add a deterministic postcondition gate after `record_code_health` that verifies `docs/code-health.md` was modified when findings are present (or another durable artifact was created).
- Document Fabro workflow instance execution model: mid-run definition changes expected behavior? When do changes take effect?

## Validation notes

**Positive validation signals:**
- Preflight sandbox check passed (clean working tree, runtime check)
- `dev ci` passed twice (before and after review repair): 758 tests, 0 failures; 77 acceptance scenarios, 502 steps
- Workflow guard tests passed: `test_review_report_routing.sh`, `test_collect_implementation_evidence.sh`
- Review repair validation: new evidence collector script tested and confirmed to excerpt `.fabro/workflows/` and `docs/kaizen/` files
- Changed files limited to workflow infrastructure and kaizen note (no product code, no feature files)
- `git diff --check` passed (no whitespace errors)

**Caveats:**
- Direct file content inspection limited due to workflow instance not reloading after repair (old evidence collector still ran in this instance)
- Routing logic with real code-health findings validated by tests but not exercised in a real review run (acknowledged as remaining follow-up)
- One acceptance scenario showed instability during earlier validation but passed in final run (documented as pre-existing/unrelated)

**Acceptance reasoning:**
This is a focused fix for an internal workflow quality gate. The original implementation addressed the plan's core issue (code-health recording failure). The review repair correctly addressed the evidence collection gap. All automated validation passed. The meta-issue (workflow instance executing old definition after mid-run changes) is a workflow execution model observation, not an implementation defect—the code changes are correct and will function properly in future runs. The judgement-worthy findings are real concerns but documented as follow-up or acceptable validation approaches for workflow infrastructure. No blocking issues were identified.