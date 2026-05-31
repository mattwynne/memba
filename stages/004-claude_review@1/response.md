# Iteration Plan Review: Deliveries Overview

## Decision: NOT READY

## Confidence: High

## Blocking Gaps

1. **Table columns not specified**: Acceptance criteria state "delivery rows are visible" but don't specify which data fields/columns should appear in the table (e.g., recipient email, message subject/title, delivery status, event timestamp, problem reason)

2. **Row ordering not in acceptance criteria**: Technical decisions mention "newest or most recently updated first" but this requirement is not captured in acceptance criteria, making it unclear whether ordering is required for this iteration

3. **Row identification unclear**: The plan mentions "stable accessible labels or IDs for browser acceptance" but doesn't specify what identifies a row for test assertions (delivery ID? combination of recipient + message? data-test-id pattern?)

## Non-blocking Improvements

1. The "options-shaped" query API could be more specific about initial parameters, even if just `[]` or `%{}`

2. Empty state (no deliveries exist) could be mentioned, though this can be discovered during implementation

3. Query return type (schema/struct vs plain map) could be specified to guide implementation

4. Error handling (query failure) could be mentioned, though basic LiveView error boundaries may suffice

## Smallest Viable Iteration

The current scope is appropriately minimal. The plan already defers pagination, filtering, search, and exports. The iteration could theoretically be smaller by:

- Showing deliveries for one message initially (defer cross-message view)
- Building the UI with fixture data first (defer query reshaping)

However, the explicit goal is "across messages" to replace "message-scoped views," so the current scope represents the right minimal useful slice.

## Required Plan Edits

**Add to Acceptance Criteria section:**

1. "The table shows columns for: recipient email/name, message subject/title, delivery status, event timestamp, and problem reason (when applicable)."

2. "Delivery rows are ordered by event timestamp descending (newest first)."

3. "Each table row has a data-test-id attribute combining delivery ID or a stable identifier for browser test assertions."

**Alternative shorter form:**

Add one combined criterion: "The table displays recipient, message title, status, timestamp, and reason columns, ordered newest first, with stable test IDs for browser assertions."

## Validation Plan

The existing validation plan is comprehensive and includes:

- Browser acceptance tests (npm test with operator scenarios)
- PhoenixTest-based LiveView tests
- Elixir/domain acceptance tests
- `dev check` passing
- Manual demo with specific steps (create club, send messages, POST events, visit /deliveries)

**Recommendation**: Once the blocking gaps are addressed, the validation plan is sufficient to prove success. The stop condition is clear: all tests pass and the manual demo shows the cross-message delivery table with specified columns and ordering.

---

{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":3,"claude_review_blocking_gaps":"Table columns not specified; Row ordering not in acceptance criteria; Row identification for browser tests unclear","claude_review_required_edits":"Add table columns to acceptance criteria; Add row ordering to acceptance criteria; Specify row identification pattern for browser tests"}}