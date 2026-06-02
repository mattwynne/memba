# Iteration Plan Review: Remove Open Tracking

## Decision: READY

## Confidence: High

## Blocking Gaps

None.

## Non-blocking Improvements

1. **Add explicit goal statement**: While the goal is inferable from context, adding a dedicated `## Goal` section at the top (before Background/Context) would improve clarity: "Remove pixel-based email open tracking from Memba's delivery model to simplify product vocabulary and avoid implying that Memba observes whether recipients read messages."

2. **Specify unsupported webhook response format**: The plan says open events should be "rejected as unsupported" but doesn't specify the expected HTTP response (status code, body structure). Clarifying whether this follows existing unsupported-event response patterns would help implementation consistency.

3. **Name specific Messaging modules**: Step 3 of the implementation plan mentions "delete or stop routing `ReportEmailDeliveryOpened` command handling" but could be more specific about which modules/files contain the command handler, event module, and aggregate transition logic.

4. **Clarify event store compatibility**: Implementation notes mention "keeping a compatibility shim" for historic opened events but could be more explicit about whether old event deserialization must work or if it's acceptable to have unopened events that cannot replay (depending on local dev/test data needs).

## Smallest Viable Iteration

The plan is already appropriately scoped. While you could theoretically split this into:
- Part 1: Backend changes (domain model, projections, webhook, Postmark config)
- Part 2: UI changes (member views, staff views, copy)

Removing a feature completely in one iteration makes sense to avoid shipping an inconsistent partial state where backend supports opened but UI doesn't, or vice versa. The current scope is the right atomic unit.

## Required Plan Edits

None required. The plan is implementable as written.

The non-blocking improvements above would strengthen clarity but are not necessary to begin implementation safely.

## Validation Plan

The plan includes a comprehensive validation approach:

**Pre-implementation:**
- All plan sections are complete (goal, scope, acceptance criteria, implementation steps, validation)
- BDD decision is explicit (Required) with named feature files
- Business and technical decisions are resolved

**During implementation:**
- Feature files updated first to guide TDD
- Layer-by-layer testing (domain → projections → webhooks → UI)
- Targeted test runs after each layer change

**Completion verification:**
1. Shared acceptance harness passes with only Sending/Delivered/Delivery problem states
2. Messaging domain tests cover delivered/delayed/bounced/spam complaint (no opened)
3. Postmark provider tests prove `track_opens` is not set
4. Postmark webhook tests prove open events are rejected without state mutation
5. Member LiveView tests show no opened groups/counts/copy
6. Staff LiveView tests show no opened status (other statuses preserved)
7. Documentation search (`rg "opened|track_opens|open tracking"`) shows only historical/irrelevant matches
8. `dev check` passes completely

**Success criteria:**
- All 14 acceptance criteria from the plan are demonstrably true
- No regression in existing delivery problem handling (delayed, bounced, spam)
- Clean separation: opened is neither emitted by current code nor exposed in current model/UI
- Stakeholder-readable acceptance features accurately describe new behavior

The validation plan is thorough and matches the scope. Implementation can proceed.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}