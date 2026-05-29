# Iteration 004 Review Report

## Decision: ACCEPT

## Confidence: High

## ADR Conformance: PASS

The implementation correctly implements all cited ADRs:

- **ADR 0004 (Event-sourced Message aggregate)**: Message aggregate exists with all required commands (SendMessage, RecordDelivered, RecordDelayed, RecordBounced, RecordSpamComplaint, RecordOpened), events, state machine rules, and idempotency checks. Terminal state transitions are properly rejected.

- **ADR 0005 (Operator email deliverability view)**: OperatorDeliverability projection stores all required fields including `delayed_reason`, `bounced_reason`, and `spam_complaint_reason`. Projector correctly preserves reason text from events.

- **ADR 0006 (Member email receipt view)**: MemberReceipt projection correctly maps delivery events to status labels (sending, delivered, opened, failed_to_deliver, reported_as_spam). Does not store reason text. Timestamp fields (delivered_at, opened_at) are properly maintained.

All three ADRs' state machine rules, projection shapes, and data flow constraints are satisfied by the implementation evidence.

## ADR Violations: None

## Blocking Issues: None

The implementation:
- Passes all 93 tests including Cucumber acceptance scenarios
- Correctly removes CRUD spike artifacts (sent_message.ex deleted)
- Enforces valid state transitions in the aggregate
- Implements idempotency for repeated events
- Provides proper separation between member and operator views
- Passes `dev check` without issues

## Bounded-Safe Fixes: None

No code changes needed. The implementation is clean and functional.

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Command dispatch pattern uses metadata for aggregate identity**
   - Files: `acceptance-tests/test_support/message_cucumber_steps.exs` (lines 36, 44, 52, 60, 68, 76, 84)
   - Smell: Commands like `RecordDelivered` are dispatched with `metadata: %{message_id: message_id}` instead of the more typical `identity: message_id`
   - Why it needs judgement: While tests prove this works correctly, typical Commanded patterns use the `identity:` option when the command struct lacks the identity field. This may reflect newer Commanded API behavior or project-specific middleware, but could confuse developers familiar with standard Commanded routing patterns.

2. **Projection schema changesets validate only primary key**
   - Files: `web/lib/memba/messaging/projections/member_receipt.ex` (line 24), `web/lib/memba/messaging/projections/operator_deliverability.ex` (line 29)
   - Smell: Changesets validate only `:message_id` as required, despite migrations marking multiple fields as `null: false`
   - Why it needs judgement: This is safe for projector-only writes (projectors always provide required fields), but creates a gap between migration constraints and changeset validation. Future direct writes or schema reuse could hit database-level errors rather than changeset errors. Consider whether stricter validation aids maintainability or is unnecessary ceremony for projection-only schemas.

3. **Manual projection table registration in config**
   - Files: `web/config/config.exs` (line 48), `web/lib/memba/testing/sandbox_support.ex` (line 31)
   - Smell: Projection tables are manually registered in a configuration list
   - Why it needs judgement: Explicit configuration is clear and safe for small numbers of projections. As projection count grows, consider whether a convention-based discovery mechanism (e.g., scanning projection module attributes) would reduce maintenance burden and registration errors.

## Suggested Fixes

None. The implementation is correct and complete as written.

## Validation Notes

**Tests demonstrate ADR conformance:**
- `message_test.exs`: Validates state machine rules, terminal state rejection, idempotency with same timestamps, and rejection of duplicate sends
- `member_receipt_projector_test.exs`: Validates status mapping per ADR 0006 (delivered→:delivered, bounced→:failed_to_deliver, etc.)
- `operator_deliverability_projector_test.exs`: Validates reason text preservation for delayed, bounced, and spam complaint events per ADR 0005
- Cucumber scenarios: Validate end-to-end member receipt view and operator deliverability view through query layer

**Dev check passed:**
- All 93 ExUnit tests pass (5.4 seconds)
- No compilation warnings
- Sandbox runtime check passed
- No working tree changes after implementation

**Manual verification of ADR compliance:**
- Read ADR 0004, 0005, 0006 in full from implementation evidence
- Traced command→event→projection flows for delivered, delayed, bounced, spam complaint, opened
- Verified status enum values match ADR 0006 table exactly
- Confirmed operator projection includes reason fields while member projection does not
- Confirmed aggregate rejects invalid transitions (delivered after bounced, delayed after delivered)

**CRUD spike removal confirmed:**
- `git diff --name-status` shows `D  web/lib/memba/messaging/sent_message.ex`
- No remaining direct Message schema inserts in implementation evidence
- All writes now go through event-sourced commands and projections