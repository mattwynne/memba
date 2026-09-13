# Iteration 061 Review

- **Decision:** ACCEPT
- **Confidence:** Medium
- **ADR conformance:** PASS

## ADR violations

1. **None identified.** The implementation evidence is consistent with the project’s CQRS, read-model, and responsibility-boundary guidance:
   - Group discovery remains distinct from effective membership and conversation authorization.
   - Authorization decisions remain server-authoritative rather than being inferred from browser state.
   - The web presentation layer uses public Membership/Messaging APIs rather than introducing projection joins as authorization shortcuts.
   - No replacement aggregate, generic permission framework, or alternative event-sourcing infrastructure was introduced.

## Blocking issues

1. **None.**

   The open `fix-review-repair-portable-comparison` item is a defect in the iteration-review workflow, not in iteration 061’s product implementation. The missing `cmp` executable should not keep the implementation rejected, particularly because no review-repair product changes remained and the subsequent full `dev ci` run succeeded.

## Bounded-safe fixes

1. **None required for this iteration.**

   The review did not identify a concrete, low-risk product refactor that would improve the implementation enough to justify another code-change cycle.

## Judgement-worthy non-blocking code-health findings

1. **Files:** Membership context/read-model modules implementing group discovery and `list_active_groups_for_member/2`; `MemberDashboardPresentation`  
   **Smell:** The discoverability-versus-participation distinction is a security-sensitive architectural seam. The APIs address closely related data and could be incorrectly consolidated by a future cleanup.  
   **Why it may need human judgement:** Discovery must never become an implicit Messaging authorization grant, and non-member presentation must not load private rows and merely hide them. The current implementation and tests conform, but maintainers should preserve the distinction explicitly during future membership work in iterations 063–065.

2. **File:** `acceptance-tests/test/cucumber_config.test.js`  
   **Smell:** The scenario inventory remains principally scenario-oriented; handling of tags attached to individual `Examples:` blocks may require additional semantics if such tags are introduced.  
   **Why it may need human judgement:** No current scenarios depend on tagged `Examples:` blocks, so this is not a present coverage gap. Before introducing them, maintainers should decide whether inventory is intended to represent an outline once or each expanded example independently.

3. **File:** `.fabro/workflows/iteration-review/scripts/verify_review_repair.sh`  
   **Smell:** The script invoked an unavailable `cmp` executable while its workflow stage still reported success.  
   **Why it may need human judgement:** This weakens the workflow’s independent before/after verification, but it is unrelated to club-group discovery and outside the iteration’s product scope. Workflow owners should decide whether to require `cmp` in the sandbox or use a portable Git-based comparison that fails explicitly when verification cannot run.

## Suggested fixes

No merge-required changes.

Recommended follow-ups:

- Preserve clear naming and focused tests around discovery summaries versus effective group membership and conversation access.
- Add `Examples:`-tag inventory coverage before the acceptance suite begins using that feature.
- Track the repair-verification portability issue separately; for example, replace `cmp` with a repository-supported comparison mechanism and ensure a failed comparison command cannot be reported as a successful verification stage.

## Validation notes

- Sandbox compilation/runtime preflight passed.
- Full `dev ci` completed successfully:
  - **1,292 ExUnit tests passed**
  - **145 browser acceptance scenarios passed**
  - **1,052 acceptance steps passed**
- Permission-sensitive acceptance coverage remained green, including direct routing and access-boundary behaviour.
- No acceptance feature files were changed during the review-repair pass.
- The review repair retained no tracked product changes.
- `verify_review_repair.sh` did **not** complete its intended portable comparison because `cmp` was unavailable, despite the stage being marked successful. This is recorded as a workflow-health issue, not an iteration-061 blocker.
- The supplied transcript does not independently demonstrate the plan’s desktop/mobile manual visual review. That limits confidence to Medium but does not reveal a behavioural or architectural defect.