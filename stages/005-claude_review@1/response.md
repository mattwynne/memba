# Plan Validation Report — Export validated member message delivery receipts as CSV

I read the complete plan file at `.fabro/workflows/plan-validation/test/fixtures/unanimous-pass/plan.md` (95 lines, all sections present: Goal, Background, Scope, Iteration Type, Acceptance Scenarios/Feature Files, Allowed acceptance feature changes, Acceptance Criteria, Open Business Decisions, Implementation Plan, Open Technical Decisions, New Capability, Validation Plan). I then cross-checked its claims against the actual codebase (router, messaging context, projections, projectors, webhook controller, `MemberEmailDeliveryPresentation`, and prior iteration/ADR/problem docs on delivery status).

## Decision: NOT READY

## Confidence: High

## Blocking gaps

1. **The plan requires an "opened" delivery status that the product explicitly does not support, and cannot currently occur in the data it reads.** Acceptance Criteria line: *"An opened recipient has `receipt_status` of `opened`, `delivery_status` of `opened`, and an empty `delivery_reason`."* The Acceptance Scenarios section also requires Gherkin coverage for an "opened" case. But:
   - `Memba.Messaging.EmailDeliveryStatus.provider_webhook_statuses/0` only contains `delivered, delayed, bounced, spam_complaint` — no `opened` (`web/lib/memba/messaging/email_delivery_status.ex`).
   - `MemberEmailDeliveryPresentation` only maps to `sent`, `delivered`, `delivery problem` — the member-facing vocabulary has no `opened` value (`web/lib/memba_web/member_email_delivery_presentation.ex`).
   - The Postmark webhook controller explicitly **rejects** the `"open"` record type as unsupported (`postmark_webhook_controller.ex:41`).
   - `EmailDeliveryOpened` is a documented no-op replay shim only — its projector clauses in both `member_email_delivery.ex` and `memba_staff_email_delivery.ex` do nothing, so no row in either read model this export queries can ever hold status `opened` today.
   - Iteration 017 ("Remove open tracking") and iteration 035 ("Obliterate the deprecated 'opened' email delivery status") deliberately removed this concept, and the follow-up note explicitly says: *"Do not reintroduce open tracking or an 'opened' status without a new product decision reversing iteration 017"* (`docs/iterations/021-staff-area-redesign/follow-ups.md:128`).
   The plan's "Open Business Decisions: None" is therefore incorrect — this acceptance criterion silently reopens a closed product decision and is not implementable against current data without a new product decision.

2. **No cross-club authorization check is specified for the new controller route, creating a plausible tenant-isolation gap.** The existing member message detail page authorizes access in two layers: the router pipeline (`club_member_required` → `require_active_club_member`, checking the *signed-in identity is an active member of the club resolved from the host subdomain*) and a **separate** check inside `MemberMessageDetail.load/3` (`require_message_in_club/2`) that verifies the specific `message.club_id` matches the resolved club. The plan's scope note says the CSV route will rely on "the existing browser pipeline access model," but a plain controller action wired only to `[:browser, :club_member_required]` gets the first check, not the second. Without an explicit message-ownership check in the new controller, an active member of Club A could download delivery receipts for a message belonging to Club B by requesting `/messages/:club-B-message-id/delivery_receipts.csv` from Club A's subdomain (since `Messaging.get_message/1` and `Messaging.list_member_email_deliverys/1` take no club scoping). Acceptance Criteria explicitly call out permissions/error states as an area to cover, and this gap is unaddressed.

## Non-blocking improvements

1. The plan doesn't name which router `scope`/pipeline the new `GET /messages/:message_id/delivery_receipts.csv` route should sit under (e.g., alongside the existing `club_member_required` live_session scope at `router.ex:69-79`); spelling this out would remove ambiguity for the implementer.
2. `Messaging.list_member_email_deliverys/1` (`web/lib/memba/messaging.ex:816`) does not currently select `recipient_email`; it only joins `MembaStaffEmailDeliveryProjection` for `reason`. The export will need an additional join to `recipient_address` (present on `EmailDeliveryProjection` or `MembaStaffEmailDeliveryProjection`) or a new query function. Naming this explicitly in the implementation plan would sharpen step 2.
3. Sorting is specified as `recipient_name` then `recipient_email`, but the existing analogous query sorts by `recipient_name` then `recipient_id` — worth a one-line note that this is a deliberate change, not an oversight.
4. Consider explicitly stating the CSV `Content-Type`/`Content-Disposition` (attachment filename) expectations, since "download" behaviour is part of the acceptance criteria's implied UX but isn't listed as a testable criterion.

## Smallest viable iteration

Drop the "opened" row/scenario entirely (four statuses: delivered, delivery problem via delayed/bounced/spam-complaint, sent, plus non-addressed exclusion and unknown-message 404) and add one explicit acceptance criterion plus an implementation step for the cross-club ownership check (reusing or extracting `MemberMessageDetail.require_message_in_club/2`-equivalent logic in the new controller). Everything else in the plan is already a minimal, coherent, single-outcome slice and should not be shrunk further.

## Required plan edits

1. Remove the "opened" acceptance criterion, its data mapping, and its mention in the Acceptance Scenarios/Feature Files section — or add an explicit, separately-flagged "Open Business Decision" proposing to reverse iteration 017/035 and get sign-off before implementation. Recommend the former.
2. Add an explicit acceptance criterion and implementation step for club-ownership authorization: requesting `/messages/:message_id/delivery_receipts.csv` for a message that exists but belongs to a different club than the requester's active club must return 404 (or 403), matching `MemberMessageDetail.require_message_in_club/2` semantics.
3. Name the router scope/pipeline the new route joins (e.g., the existing `pipe_through [:browser, :club_member_required]` scope) so the pipeline-derived `club_id` is available to the new controller for the ownership check in edit 2.
4. Note the additional join/field needed to obtain `recipient_email`, since the current `list_member_email_deliverys/1` doesn't select it.

## Validation plan (for the corrected plan)

- Controller tests: 200 with correct headers/columns/ordering for a message with delivered/delivery-problem/sent recipients; empty `delivery_reason` handling; RFC 4180 escaping for a name/subject containing a comma or quote; 404 for unknown `message_id`; 404 (or 403) for a message belonging to a different club than the requester's active club.
- Manual check: create a message with delivered, delayed/bounced, and sent recipients across two clubs, download CSV from the owning club's subdomain, verify columns/order/values, then attempt the cross-club download and confirm it is rejected.
- `dev check` green on the committed diff, including the updated `member_message_deliverability.feature` scenarios (with "opened" removed).

{"context_updates":{"claude_review_decision":"NOT READY","claude_review_confidence":"High","claude_review_blocking_gap_count":2,"claude_review_blocking_gaps":"Acceptance criteria require an 'opened' receipt_status/delivery_status that the product explicitly retired (iterations 017/035, ADR 0006) and that cannot occur in the read models this export queries; Implementation plan omits a cross-club message-ownership authorization check for the new controller route, risking a tenant-isolation leak (the existing MemberMessageDetail.require_message_in_club check is not replicated)","claude_review_required_edits":"Remove the 'opened' scenario/criterion or add an explicit Open Business Decision to reverse iterations 017/035 with sign-off; add an acceptance criterion and implementation step requiring 404/403 when the requested message does not belong to the requester's active club; name the router scope/pipeline for the new route; specify the join needed to obtain recipient_email"}}