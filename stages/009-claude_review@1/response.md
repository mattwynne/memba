# Independent Plan Review: Iteration 019 - Inbound Club Messages by Email

## Decision: NOT READY

## Confidence: High

## Blocking Gaps

1. **Idempotency mechanism unresolved**: The plan acknowledges webhook retry risks and duplicate message creation but does not include database schema changes or implementation steps to prevent duplicates. No migration is specified for storing `provider_message_id`, no unique constraints, no deduplication logic. The "Open Technical Decisions" section defers this to implementation investigation, but this is an architectural decision that affects data modeling and must be resolved during planning.

2. **Resend payload schema unknown**: The plan defers investigating "exact Resend inbound webhook payload fields" to implementation time. Field names for text body, HTML body, attachments, headers, message ID, and envelope recipients must be researched and documented during planning so implementation steps can reference specific field mappings rather than generic "translate payload" guidance.

3. **Webhook signature verification undefined**: Security verification approach should be decided before implementation. The plan asks whether "Resend inbound webhooks require signature verification or share existing webhook verification mechanisms" but leaves this open. This is a security-critical decision that belongs in planning, not implementation.

## Non-blocking Improvements

1. **Rejection email delivery timing**: The plan leaves synchronous vs. asynchronous rejection email delivery as an implementation-time decision. While this can be refactored later, deciding upfront would result in cleaner initial implementation.

2. **Quote/signature stripping specificity**: The plan says "prefer conservative stripping" but could name a specific library, pattern, or reference implementation to reduce implementation uncertainty.

3. **Alternate email lookup strategy**: The plan doesn't specify whether alternate email lookup should check person records, person_emails join table, or both. This detail would help implementation.

## Smallest Viable Iteration

The current scope already represents a reasonable minimum for this capability. The only way to make it meaningfully smaller would be to defer alternate email address support, skip quote/signature stripping, and accept messages in full with basic rejections. This would reduce polish and user value by ~25% but save only ~20% implementation effort.

**Recommendation**: Keep current scope but resolve blocking gaps rather than cutting scope.

## Required Plan Edits

1. **Research and document Resend webhook payload structure** before finalizing the plan:
   - List actual field names for: text body, HTML body, attachments, headers, message ID, envelope from/to, timestamp
   - Document payload examples in the plan or reference Resend API documentation
   - Update implementation steps 10-11 to reference specific field mappings

2. **Decide idempotency approach** and add explicit implementation steps:
   - Add step 2a: "Create migration to add `provider_message_id` string field to messages table (or new `inbound_emails` tracking table)"
   - Add step 2b: "Add unique index on `provider_message_id` scoped to provider name"
   - Add step 6a: "Before creating message, check if provider_message_id already exists; if duplicate, log and return success without creating duplicate message"
   - Add test case to step 12: "duplicate webhook delivery with same provider_message_id creates only one message"
   - Remove idempotency from "Open Technical Decisions" and document chosen approach

3. **Decide and document webhook verification**:
   - Research whether Resend inbound webhooks use the same verification mechanism as delivery status webhooks
   - Document required verification steps (signature header name, algorithm, secret source)
   - Add verification logic to implementation step 10 or reference existing verification helper
   - Remove webhook verification from "Open Technical Decisions"

4. **Move resolved decisions** from "Open Technical Decisions" to plan body or accept them as implementation details:
   - If rejection emails should be asynchronous (likely better for webhook response time), state this in step 9
   - If quote/signature stripping should use a specific approach, name it; otherwise accept "conservative, example-covered" as sufficient

## Validation Plan

After the required edits, the plan will be ready when:

1. ✅ Resend payload fields are documented with specific field names
2. ✅ Database migration for provider_message_id is in implementation plan
3. ✅ Idempotency check is in implementation plan
4. ✅ Webhook verification approach is documented
5. ✅ Implementation plan includes test for duplicate webhook prevention
6. ✅ "Open Technical Decisions" section no longer lists blocking decisions

The existing validation plan (dev check, targeted tests, Cucumber scenarios, manual demo) is thorough and appropriate once these gaps are filled.

**After implementation completes**, success is proven by:
- All @wip tags removed from Cucumber scenarios
- `member_message_deliverability.feature` passes with inbound scenarios
- Manual demo confirms: inbound email creates club message, rejections work, duplicates prevented, alternate addresses work
- `dev check` passes

---

{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":3,"claude_review_blocking_gaps":"Idempotency mechanism unresolved - no database schema or implementation steps for preventing duplicate messages from webhook retries; Resend webhook payload schema unknown - field names must be researched and documented during planning; Webhook signature verification approach undefined - security-critical decision must be resolved before implementation","claude_review_required_edits":"Research and document Resend inbound webhook payload field names and structure; Add database migration for provider_message_id with unique constraint to implementation plan; Add idempotency check logic to implementation plan; Decide and document webhook signature verification approach; Add test case for duplicate webhook prevention"}}