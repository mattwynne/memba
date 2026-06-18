Now I'll review the plan against each readiness criterion.

---

# Iteration 035 Plan Review

## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. **Grep pattern specificity**: The plan mentions grepping for `opened`/`Opened` but doesn't specify case-sensitivity or word boundaries. Recommend `grep -i '\bopened\b'` or similar to avoid false positives like "reopened" or variable names containing "opened" as a substring.

2. **Regression test location**: The plan doesn't specify where the replay-safety regression test will live (e.g., `test/memba/messaging/projectors/` or a dedicated `test/memba/event_replay_test.exs`). Not blocking since it's standard to determine during implementation, but could be clearer.

3. **Command dispatch routing detail**: The plan says "delete command and any dispatch routing/registration" but doesn't name the file(s) where command routing lives. Given the event-sourcing architecture, this is likely in a router/dispatcher module, but naming it would reduce discovery work.

## Smallest viable iteration

This iteration is already tight and focused. The only potential split would be:
- **Iteration 035a**: Remove all active code (command, normalization, presentation, webhook, projector behaviour, tests)
- **Iteration 035b**: Add replay-safety regression test and confirm shim adequacy

However, the current single iteration is preferable because:
- The replay-safety regression test is the critical validation that the shim approach works
- Splitting creates risk of shipping step (a) without confirming safety
- The scope is manageable and coherent

**Recommendation**: Ship as one iteration per the current plan.

## Required plan edits

None. The plan is ready for implementation.

## Validation Plan

The plan's validation is concrete and comprehensive:

1. **ExUnit proof**: All test suites pass with "opened" assertions removed
2. **Replay-safety proof**: New regression test persists and replays a historic `EmailDeliveryOpened` event, asserting projections/read models unaffected and rebuild succeeds
3. **Grep proof**: Baseline-vs-final grep shows no `opened`/`Opened` outside documented shim in `lib/`, and none in `test/`/`acceptance-tests/` except shim coverage
4. **Integration proof**: Full `dev check` passes

**How to prove success**:
- Run the new regression test: it should show a historic `EmailDeliveryOpened` event deserializes, replays through aggregate and projectors, and leaves state unchanged
- Run grep: `grep -r "opened" lib/ test/ acceptance-tests/` should return only the documented shim elements (event module, aggregate no-op, projector no-ops) plus the regression test
- Run `dev check`: all checks green
- Inspect member/staff email delivery surfaces (dashboard, message detail, staff diagnostics): no "opened" status or count visible

**Clear stop condition**: 
When grep shows only documented shim, all tests pass including the new regression test, and `dev check` is green.

---

## Detailed Assessment

### 1. Goal Clarity ✓

- **Clearly articulated**: Yes. The goal is to remove the deprecated "opened" status everywhere except a documented event-store tombstone.
- **User/business outcome**: Yes. "After this iteration there is one clear answer to 'is opened a status Memba tracks?' — no — and the codebase stops carrying the half-removed husk that currently misleads contributors, the design system, and the dev seeds/gallery."
- **Intended beneficiary**: Contributors, the design system, and dev seeds/gallery users are explicitly named as beneficiaries in the New Capability section.

### 2. Scope Focus ✓

- **One coherent outcome**: Yes. The scope is tightly focused on obliterating "opened" status references while preserving replay safety.
- **Could it be smaller while still useful**: No. The plan already acknowledges a potential split (removing code vs. adding regression test) but correctly argues this iteration should ship together to ensure the shim approach is validated before delivery.
- **Non-goals and boundaries clear**: Yes. Out-of-scope section explicitly excludes iteration 034 work, changes to tracked statuses, marketing content, and full event-store rewriting.

### 3. Acceptance Criteria, BDD Decision, and Business Decisions ✓

- **Concrete, clear, complete, testable**: Yes. Six specific, objectively verifiable acceptance criteria covering deletion, shim retention, surface visibility, regression test, test cleanup, and `dev check`.
- **Coverage**: Happy path (shim allows replay), edge case (historic event), permissions (N/A for internal cleanup), error states (replay without crash), data/state changes (projections/read models unaffected).
- **Iteration classified**: Yes. "Technical/engineering cleanup. There is no new user-observable behaviour."
- **BDD scenario decision**: Yes. Plan includes explicit `## Acceptance Scenarios / Feature Files` section with clear rationale: "**Not useful for this slice.** This is internal cleanup of an already-removed feature... Correctness is verified by ExUnit and `dev check`."
- **Unresolved business decisions**: No. "None known. 'Opened' is already not a tracked product status; this is cleanup."

### 4. Implementation Plan and Technical Decisions ✓

- **Clear, ordered, specific steps**: Yes. Nine sequential steps from inventory through final `dev check`.
- **Files/modules named**: Yes. Names specific files:
  - `lib/memba/messaging/commands/report_email_delivery_opened.ex`
  - `lib/memba/messaging.ex` (lines ~430, 439)
  - `lib/memba_web/member_email_delivery_presentation.ex`
  - `lib/memba_web/controllers/postmark_webhook_controller.ex`
  - `lib/memba/messaging/projectors/member_email_delivery.ex`
  - `lib/memba/messaging/projectors/memba_staff_email_delivery.ex`
  - `lib/memba/messaging/events/email_delivery_opened.ex`
  - `lib/memba/messaging/message.ex`
- **Data model, API, UI, workflow changes clear**: Yes. Changes to command handling, read-model normalization, presentation layer, webhook handling, and projectors are all explicit.
- **Unresolved technical decisions**: Two noted (projector clause necessity, aggregate alias retention) but correctly scoped as "implementation details that should not need product decisions." These are appropriate to resolve during implementation.

### 5. Expected Capability and Validation ✓

- **What we can do after**: "Contributors, the design system, and the dev seeds/gallery have a single, consistent source of truth: Memba does not track an 'opened' delivery status."
- **How to prove success**: Four-part validation plan (ExUnit, regression test, grep, `dev check`).
- **Clear stop condition**: Grep shows only documented shim, all tests pass, `dev check` green.

---

## Additional Strengths

1. **Event-sourcing awareness**: The plan demonstrates sophisticated understanding of event-sourcing replay safety and chooses an appropriate ignore-on-replay shim strategy rather than attempting dangerous event-store rewrites.

2. **Completeness across layers**: Touches command, event, aggregate, projectors, read models, presentation, webhook, ExUnit tests, and acceptance tests — a thorough removal.

3. **Risk mitigation**: Explicitly calls out replay safety as the main risk and requires a regression test that actually exercises rebuild (not just forward dispatch).

4. **Prevents future confusion**: Requires clear comments on shim elements to prevent "helpful" removal by future contributors.

5. **Related problems**: Links to the specific problem note this iteration resolves.

6. **Context/background**: Provides clear rationale (surfaced during gallery walk work) and references the prior iteration 017 that started this deprecation.

---

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}