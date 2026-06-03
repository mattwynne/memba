# Iteration Plan Review: Inbound Club Messages by Email

## Decision: READY

## Confidence: High

This iteration plan is comprehensive, well-structured, and ready for implementation.

## Blocking Gaps

None.

## Non-Blocking Improvements

The following are minor observations that don't block implementation but could provide additional clarity:

1. **Quote/signature stripping implementation**: The plan specifies "conservative and plain-text only" but leaves the specific library or heuristic approach to implementation. This is appropriate given the heuristic nature of the problem, but consider documenting the chosen approach during implementation for future reference.

2. **Rejection email templates**: The plan provides clear guidance ("concise: reason plus support/contact guidance") but doesn't specify exact copy. This is acceptable for implementation but may want stakeholder review during delivery to ensure tone matches brand voice.

3. **Example webhook payload**: While the plan clearly lists expected Resend payload fields, including a concrete example payload in the implementation or tests would help validate assumptions earlier. The risks section already acknowledges payload details may differ.

4. **Malformed payload HTTP responses**: Step 16 mentions treating missing required fields as "malformed/unprocessable," but the specific HTTP status codes (400 vs 422 vs 500) could be more explicit. This is minor and can be decided during implementation following Phoenix conventions.

## Smallest Viable Iteration

The plan already represents the smallest viable iteration. Each in-scope item is necessary:

- **Address display**: Required for members to know where to email
- **Webhook handling**: Required to receive emails
- **Authorization**: Required for security
- **Message creation**: Required for core functionality
- **Rejection handling**: Required for usable error states
- **Idempotency**: Required for production reliability

Removing any of these would leave an incomplete or unusable feature. The out-of-scope items (attachments, HTML, replies, custom domains) are appropriately deferred.

## Required Plan Edits

None. The plan satisfies all readiness criteria.

## Validation Plan

The plan includes comprehensive validation:

### Automated validation
- `dev check` ensures test suite, code quality, and type checks pass
- Targeted messaging context tests for provider-neutral inbound API
- Targeted Resend webhook controller/parser tests  
- Targeted mailer tests for rejection emails
- Cucumber configuration tests for @wip scenario handling
- Full Cucumber feature file execution after @wip removal

### Manual validation
The 10-step manual demo systematically covers:
1. Basic inbound posting (primary address)
2. Alternate sender address handling
3. Unknown sender rejection
4. Non-member rejection  
5. Attachment rejection
6. HTML-only rejection
7. Quote/signature stripping verification

This combination of automated and manual validation provides high confidence the iteration succeeds.

### Success criteria
Clear stop condition: All acceptance criteria met, tests pass (including shared Cucumber scenarios), manual demo succeeds, and `dev check` remains green.

---

## Readiness Assessment by Dimension

### 1. Goal Clarity ✓
- **Goal**: Enable members to post club messages by emailing a club-specific address
- **Beneficiary**: Active club members  
- **Outcome**: Member-visible inbound email address and working email-to-message flow
- The new capability section clearly states what should work after this iteration

### 2. Scope Focus ✓
- Focused on one coherent outcome: basic inbound email posting for club messages
- Detailed out-of-scope section (replies, attachments, HTML, channels, custom domains, moderation) shows deliberate scope boundaries
- Cannot be meaningfully smaller while remaining useful

### 3. Acceptance Criteria & Scenarios ✓
- 22 concrete, testable acceptance criteria covering:
  - Happy path (posting from primary/alternate addresses)
  - Edge cases (unknown slugs, missing plain text after stripping)
  - Authorization (active membership required)
  - Error states (7 rejection scenarios with clear user feedback)
  - Data changes (message creation, delivery records, audit events)
- Explicit "Acceptance Scenarios / Feature Files" section naming `member_message_deliverability.feature`
- 7 specific @wip scenarios listed with clear examples
- Matt's approval of scenario language documented
- "Open Technical Decisions" section explicitly states no blocking decisions remain

### 4. Implementation Plan ✓
- 24 ordered, specific steps
- Files/modules named: `MembaWeb.ResendWebhookSignature`, `messaging_inbound_email_sources` table, feature file paths
- Integration points clear: Resend webhooks, existing message command, outbound delivery path
- Events named: `InboundClubEmailAccepted`, `InboundClubEmailRejected`
- Data model specified: projection table with unique constraint on `{provider, provider_message_id}`
- Follows event-sourcing pattern per project guidelines

### 5. Expected Capability & Validation ✓
- Clear new capability statement
- Comprehensive validation plan (automated + manual)
- Explicit stop condition

---

## Alignment with Project Standards

The plan aligns with project guidelines from docs/reference/:
- Event-sourced aggregates for idempotency ✓
- Provider-neutral internal API with Resend adapter ✓
- Test coverage (unit, integration, acceptance) ✓  
- `dev check` requirement ✓
- Phoenix 1.8 patterns ✓

---

This plan demonstrates thorough preparation and is ready for implementation without requiring edits.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}