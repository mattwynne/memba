# Independent Plan Review: Iteration 020

## Decision: READY

## Confidence: High

## Blocking Gaps

None.

## Non-Blocking Improvements

1. **Clarity on existing vs. new implementation**: The plan could make more explicit which Postmark capabilities are already implemented (outbound member messages from iteration 008), which need implementation (inbound email), and which need verification/testing (auth email, rejection email paths). This is inferable from "verify or add" language but not completely explicit.

2. **Dependency precision**: The plan says "start after iteration 019" but could be more explicit: "This iteration cannot start until iteration 019 is delivered AND inbound email with Resend has been observed working in production." The background implies this, but stating it explicitly in the implementation plan would remove ambiguity.

3. **Effort indication**: The plan doesn't include an estimate or complexity signal. This appears to be a 2-4 day technical slice but isn't stated.

These improvements would enhance clarity but do not block implementation.

## Smallest Viable Iteration

**This plan already represents the smallest viable iteration for the stated goal.**

The goal is enabling Matt to cut production email over to Postmark with a documented runbook and rollback path. To achieve this safely, the iteration must:

- Add Postmark inbound email support (the main new capability)
- Verify Postmark outbound member messages still work correctly
- Verify Postmark auth email configuration and behavior
- Verify rejection emails work through Postmark
- Keep Resend as a tested fallback
- Document the complete cutover and rollback procedures

Any smaller scope would leave an incomplete migration that cannot be safely executed. You cannot migrate only some email types while maintaining the member-facing address `<club-slug>@clubs.memba.io`.

The plan correctly excludes actual production changes (out of scope for delivery) and new features (out of scope for this migration).

## Required Plan Edits

**None.**

The plan is ready for implementation as written.

## Validation Plan Assessment

The plan includes a comprehensive validation strategy (lines 121-147):

**Automated validation:**
- Focused tests for Postmark inbound parsing/translation
- Regression tests for provider-neutral API (iteration 019)
- Regression tests for Resend fallback
- Tests for Postmark outbound metadata and delivery-status correlation
- Tests for Postmark auth configuration and error handling
- `dev check` passing

**Manual validation:**
A 7-step smoke test covering:
1. Postmark dashboard/DNS/webhook configuration verification
2. Production secrets correctly set for Postmark
3. Magic-link auth email delivery and sign-in flow
4. Outbound member message delivery and delivery-status webhook updates
5. Inbound club messages from active members
6. Rejection emails for unsupported senders/attachments
7. Rollback path verification (Resend secrets/webhooks still available)

This validation plan is sufficient to prove:
- All email types work through Postmark
- Existing behavior is preserved
- Resend fallback remains functional
- Matt can safely perform the production cutover

## Detailed Assessment

### 1. Goal Clarity ✓

**Goal:** "After this iteration, Matt can manually cut production over to Postmark for member-message outbound delivery, inbound club-message email, rejection emails, and magic-link authentication using a documented runbook, while keeping Resend available as a rollback/fallback provider."

- Clear beneficiary: Matt (operator)
- Clear outcome: Can perform manual production cutover
- Explicit about what is enabled vs. executed
- User-facing behavior unchanged (technical/engineering iteration)

### 2. Scope Focus ✓

**In scope:**
- Postmark inbound email support for club messages
- Provider-neutral translation of Postmark payloads
- Preservation of iteration 019 behaviors (authorization, rejection, idempotency)
- Outbound member-message delivery via Postmark (verification)
- Magic-link auth via Postmark (verification)
- Rejection email handling via Postmark
- Complete operational documentation and runbook
- Automated tests
- Resend fallback preservation

**Out of scope:**
- Actual production cutover (Matt performs manually)
- Business rule changes
- New inbound email features
- Removing Resend support
- Webhook authentication expansion

The scope is coherent, focused on migration enablement, and appropriately sized. It addresses all email types in a single slice to enable a complete migration while keeping behavior unchanged.

### 3. Acceptance Criteria, BDD Decision, and Business Decisions ✓

**Acceptance criteria** (lines 61-120): Concrete, testable, and comprehensive:
- Postmark inbound parsing/translation works
- Sender authorization preserved
- Attachments/non-plain-text rejected appropriately
- Idempotency handling works
- Provider selection configurable for all email types
- Configuration failures are clear
- Resend remains selectable for rollback
- Documentation specifies exact variables/secrets/setup
- Manual smoke tests documented
- Local dev remains deterministic
- `dev check` passes

Covers happy paths, edge cases, error states, configuration, and rollback.

**BDD decision** (lines 001-060): Explicitly addressed with clear rationale:
- Iteration type: Technical/engineering
- User behavior unchanged
- Existing acceptance scenarios (iteration 019) already express the behavior
- Provider plumbing better tested with integration/unit tests
- No new Gherkin scenarios needed

This decision is appropriate and well-justified.

**Business decisions** (lines 061-120): All resolved during planning:
- Migrate all email paths to Postmark (not just club messages)
- Keep `<club-slug>@clubs.memba.io` unchanged
- Delivery prepares code/docs only; Matt performs cutover manually
- Preserve Resend as tested fallback

### 4. Implementation Plan and Technical Decisions ✓

**Implementation plan** (lines 061-120): 16 detailed, ordered steps:
1. Start after iteration 019 completion and observation
2. Inspect iteration 019's provider-neutral API/idempotency/tests
3. Inspect existing Postmark capabilities
4. Determine Postmark inbound routing approach
5. Add Postmark inbound parser/controller
6. Reuse provider-neutral command/API
7. Add Postmark idempotency support
8. Add tests for Postmark inbound
9. Verify/add tests for Postmark outbound metadata
10. Verify/add tests for Postmark auth configuration
11. Verify rejection email delivery
12. Update `docs/postmark-email.md`
13. Update/add runbook documentation
14. Update ADRs as needed
15. Run targeted tests
16. Run `dev check`

Names specific files (`docs/postmark-email.md`, `docs/human-todo.md`), modules (inbound parser/controller, provider-neutral API), and integration points (delivery-status webhooks, auth email configuration).

**Technical decisions** (lines 121-180): Appropriately scoped as implementation-time investigation questions:
- Postmark inbound payload shape and idempotency field
- Routing approach (separate vs. dispatching webhook route)
- Domain/MX setup for `clubs.memba.io`
- Attachment metadata availability
- Provider-specific inbound authentication (if available and non-disruptive)

These are discovery questions requiring Postmark API inspection, not blocking design decisions.

### 5. Expected Capability and Validation ✓

**New capability** (lines 121-180):
"Memba can receive, send, and operationally validate all production email paths through Postmark while preserving Resend as a fallback. Matt has a concrete runbook for a manual production cutover and rollback."

Clear before/after state:
- Before: Resend for inbound; Postmark for outbound but not fully validated/documented
- After: All email paths work with Postmark, fully tested and documented with cutover runbook

**Stop condition:** Clear - all tests pass, runbook documented, `dev check` green.

### Risks/Follow-ups

The plan acknowledges realistic risks (lines 121-180):
- Postmark payload differences may require API adjustments
- DNS/MX setup requires manual work
- Production cutover risks (mitigated by runbook/rollback)
- Webhook authentication remains a follow-up concern
- Dual-provider maintenance cost (accepted as valuable during provider validation)

Thoughtful and realistic risk assessment with documented mitigations.

## Alignment with Gemini Review

The Gemini review reached the same conclusion: READY with High confidence and 0 blocking gaps. Both reviews agree this plan is thorough, well-structured, and ready for implementation.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}