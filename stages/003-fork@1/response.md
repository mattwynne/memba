# Iteration Plan Review: 005-browser-acceptance-harness

## Decision: NOT READY

## Confidence: Medium

The plan is well-structured with good validation steps and clear implementation guidance, but has important gaps in acceptance criteria completeness and undocumented technical decisions that should be resolved before implementation.

## Blocking Gaps

1. **Goal is infrastructure-focused, not outcome-focused**: The goal describes building a "harness" and "Playwright-driven routes" rather than the business/user outcome. What developer/operator problem does this solve? What workflow becomes possible?

2. **Acceptance criteria lack error handling and edge cases**:
   - What happens when webhook receives events for non-existent messages?
   - What happens when webhook receives malformed JSON or unknown event types?
   - What validation do LiveView forms have (e.g., empty club name, invalid email)?
   - What error states should be displayed to users?
   - What HTTP status codes should webhook return for various scenarios?

3. **Webhook authentication strategy undocumented**: Even if signature verification is deferred to a later iteration, the plan should explicitly state whether the initial webhook has NO authentication, basic auth, or placeholder auth. This is a security decision that affects the implementation.

4. **"Appropriate non-browser pipeline" is unspecified**: Step 3 says to add webhook route under "an appropriate non-browser pipeline" but doesn't name which one. Is this the existing `:api` pipeline, a new `:webhook` pipeline, or something else?

5. **Webhook handler implementation approach unclear**: Step 6 says "build the Postmark webhook controller/handler" but doesn't specify whether this is a Phoenix controller, a plug, a LiveView, or a GenServer. The architectural choice should be explicit.

## Non-blocking Improvements

1. **Add explicit non-goals section**: While risks mention what's deferred, an explicit "Not in Scope" or "Non-Goals" section would clarify boundaries (e.g., "Visual design polish", "Production webhook retry logic", "Webhook signature verification").

2. **Clarify existing vs new code**: The plan lists context functions to add but doesn't specify which contexts/schemas already exist vs need creation. For example, do `Club`, `Person`, `Member`, `Message`, `Delivery` schemas already exist?

3. **Add permission/authorization criteria**: Do these routes require authentication? Are there any permission checks (e.g., can any user view any club, or is there access control)?

4. **Make LiveView implementation steps more specific**: Step 5 says "build LiveViews with simple forms/actions" but could specify:
   - What Phoenix.Component modules are needed?
   - What form fields each LiveView requires?
   - What mount/handle_event functions are needed?

5. **Specify webhook contract examples**: Include example Postmark webhook payloads in the plan or reference where they're documented, so implementation has a concrete target.

## Smallest Viable Iteration

The current scope is already fairly minimal for achieving browser-backed acceptance testing. However, it could potentially be split:

**Option A (Recommended - keep current scope):** The plan as written is the smallest useful increment that enables browser testing of the full member message flow.

**Option B (If truly needed to reduce risk):** 
- **Iteration 5a:** LiveView routes + browser acceptance tests only (no webhook)
- **Iteration 5b:** Postmark webhook + delivery status browser tests

However, Option B delays proving the complete flow and adds iteration overhead. **Recommend keeping current scope** but addressing the blocking gaps.

## Required Plan Edits

### 1. Rewrite Goal (add to top of plan)
```markdown
## Revised Goal

Enable developers and QA to validate complete member message delivery flows through real browser UI, reducing the gap between domain-level acceptance tests and production behavior. After this iteration, the team can demo club messaging features in a browser, inspect delivery status updates, and run automated browser acceptance tests alongside existing domain tests.
```

### 2. Expand Acceptance Criteria (replace existing AC 1 and 2)

```markdown
1. Real browser routes under `/clubs`, `/clubs/:club_id`, `/messages/:message_id` that support:
   - Creating a club (name required, error shown if blank)
   - Creating a person (email required, error shown if blank/invalid)
   - Adding a member to a club (club and person must exist)
   - Sending a club message (requires club, subject, body)
   - Viewing addressed recipients and delivery records for club messages
   - Display "Club not found" when visiting `/clubs/:club_id` with non-existent ID
   - Display "Message not found" when visiting `/messages/:message_id` with non-existent ID

2. `POST /webhooks/postmark` that:
   - Accepts Postmark-style delivery, delay, bounce, spam, and open events
   - Dispatches appropriate Messaging context status-reporting commands
   - Returns 200 OK for successfully processed events
   - Returns 404 when event references non-existent message
   - Returns 422 for malformed JSON or missing required fields
   - Returns 400 for unknown event types
   - **Has NO authentication in this iteration** (signature verification deferred to iteration X)
   - Logs all received webhook events at info level
```

### 3. Add Non-Goals Section (after Acceptance Criteria)

```markdown
## Not in Scope

- Visual design polish or branding
- Production webhook retry logic
- Webhook signature verification (deferred to iteration X)
- Rate limiting or abuse prevention
- Operator deliverability UI (tagged with @todo-web)
- Multi-tenancy or user authentication
- Real email sending (delivery records are synthetic)
```

### 4. Update Implementation Step 3

```markdown
3. Add `POST /webhooks/postmark` under the `:api` pipeline (create if it doesn't exist):
   - Pipeline should skip CSRF protection and parse JSON
   - Route to `MembaWeb.WebhookController, :postmark`
```

### 5. Update Implementation Step 6

```markdown
6. Build `MembaWeb.WebhookController.postmark/2` as a Phoenix controller action:
   - Pattern match on `params["RecordType"]` for event type ("Delivery", "Bounce", etc.)
   - Extract `MessageID` and event details from Postmark payload structure
   - Call appropriate `Memba.Messaging.report_delivery_*` function
   - Return `{:ok, %{status: "processed"}}` JSON on success
   - Return appropriate error status codes and messages for failure cases
```

### 6. Document Technical Decision (add to Open Technical Decisions or create new section)

```markdown
## Technical Decisions Made

- **Webhook Authentication**: None in this iteration. Signature verification deferred to later provider integration iteration. Document this as a known security gap for local/staging environments.
- **Webhook Implementation**: Phoenix controller with pattern matching, not LiveView or plug.
- **Pipeline**: Use `:api` pipeline for webhook (create if needed).
- **Error Handling**: Webhook returns standard HTTP status codes; LiveViews display inline error messages.
```

## Validation Plan

The existing validation plan is strong. Enhance it with:

1. **Acceptance Criteria Validation**:
   - Run browser acceptance tests and confirm they exercise all AC 1 scenarios (create, view, error states)
   - Use curl or Postman to POST various Postmark webhook payloads to `/webhooks/postmark` and confirm AC 2 behaviors (200, 404, 422, 400 responses)
   
2. **Error Path Testing**:
   - PhoenixTest: Test form validation errors (blank club name, invalid email)
   - PhoenixTest: Test 404 routes for non-existent clubs/messages
   - Unit test webhook controller with malformed/missing/unknown payloads

3. **Integration Testing**:
   - Run `npm test` from `acceptance-tests/` → should use `not @todo-web` and pass
   - Run domain acceptance via `dev check` → should run all scenarios including `@todo-web` and pass
   - Manual demo: Complete flow from club creation → message send → webhook POST → receipt status update visible in browser

4. **Code Quality**:
   - `dev check` passes
   - PhoenixTest coverage for all LiveView routes
   - ExUnit tests for webhook controller
   - Credo/formatter clean

---

**Summary**: Address the 5 blocking gaps (especially acceptance criteria and technical decisions) and incorporate the required plan edits. The scope is appropriate; the validation plan is solid. With these clarifications, the plan will be ready for implementation.