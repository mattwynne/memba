# Iteration 038 Review: Email Delivery Handoff Boundary

## Decision: ACCEPT

## Confidence: Medium

The implementation appears to satisfy the iteration goal: outbound email provider dispatch has been moved behind an asynchronous `EmailDelivery` lifecycle, `send_club_message/2` is no longer coupled to provider availability, failed dispatches are observable, and manual/internal retry exists. `dev ci` passed, including the full acceptance suite.

Confidence is medium rather than high because the main remaining concerns are architectural/code-health judgement calls around projection purity, PubSub-driven dispatch, and failure recovery semantics rather than obvious behavioural failures.

## ADR conformance: PASS

No ADR violation is evident from the supplied implementation evidence.

The plan itself did not cite a specific ADR. The implementation appears consistent with the intended Commanded/CQRS/event-sourced architecture in the broad sense: domain command acceptance remains separate from read-model/projection state, and provider delivery is represented as read-model dispatch lifecycle rather than as synchronous command handling.

The reference-doc-level concerns below — especially projection temporal coupling and PubSub as a business-process nudge — are worth human judgement, but I do not see enough evidence to classify them as binding ADR failures.

## ADR violations

1. None identified.

## Blocking issues

1. None.

The implementation is plan-conforming enough to merge from this review perspective. I did not find a behavioural gap that requires a new implementation pass before merge.

## Bounded-safe fixes

1. **Mark or move provider-dispatch helpers that remain on `Memba.Messaging`**
   - File: `web/lib/memba/messaging.ex`
   - If `deliver_to_provider/1` or request-building helpers remain public on the context but are now dispatcher-only implementation details, mark them `@doc false`, make them private where possible, or move them behind `Memba.Messaging.EmailDeliveryDispatcher` / a focused collaborator.
   - This reduces accidental external coupling to what should now be infrastructure internals.

2. **Add structured logging around dispatch success/failure/retry**
   - File: `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - Low-risk observability improvement:
     - delivery claimed
     - provider success
     - provider error
     - retry requested
     - claim skipped because status changed
   - Include `delivery_id`, `message_id`, provider module, status, and sanitized error/detail where appropriate.

3. **Defensively normalize provider exceptions into failed dispatches**
   - File: `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - The plan covers provider errors, and provider adapters likely return `{:error, reason}`. Still, provider boundaries are a reasonable place to rescue/log unexpected exceptions and mark the delivery `failed` with diagnostics rather than crashing the dispatcher and leaving a record indefinitely in `dispatching`.
   - This should be done carefully so programming errors remain visible in logs.

4. **Centralize valid email delivery statuses**
   - Files likely involved:
     - `web/lib/memba/messaging/email_delivery.ex`
     - `web/lib/memba/messaging/projectors/email_delivery.ex`
     - migrations / tests / views that reference statuses
   - If statuses are currently repeated across schema validation, dispatcher clauses, UI/status labels, tests, and migrations, extract a single status vocabulary module or schema constant.
   - This helps avoid drift between lifecycle statuses: `pending`, `dispatching`, `sent`, `failed`, and preserved webhook/provider statuses.

5. **Consider a DB-level check constraint if the status vocabulary is already stable**
   - File: relevant migration for `email_deliveries`
   - The plan allowed “database constraints or schema validation.” Schema validation is acceptable, but a check constraint would provide better protection for operational/manual updates.
   - This is bounded-safe only if the full existing status vocabulary is known and centralized; avoid hand-copying a partial list that could reject historical/provider webhook statuses.

## Judgement-worthy non-blocking code-health findings

1. **File(s): `web/lib/memba/messaging/projectors/email_delivery.ex`**
   - **Smell:** Projection appears to query current member state to obtain email data when handling `MessageSent`.
   - **Why it may need judgement:** In event-sourced systems, projections are usually most reliable when they are deterministic functions of event data. Querying current membership state introduces temporal coupling: the projected delivery can differ depending on when the projector runs relative to member email changes/deletions.
   - **Why not blocking:** This may already be an accepted Memba trade-off, and the iteration plan explicitly chose to use existing `EmailDelivery` records rather than introduce a new delivery-request event/table.

2. **File(s): `web/lib/memba/messaging/projectors/email_delivery.ex`**
   - **Smell:** Missing/blank member email may silently skip creating an `EmailDelivery`.
   - **Why it may need judgement:** If the domain has accepted/recorded `MessageSent`, silently skipping the delivery read model can make the system appear to have sent a message with no attempted delivery or diagnostic record.
   - **Potential follow-up:** Consider whether “no deliverable email address” should become an explicit failed/undeliverable delivery record, a command preflight failure, or enriched event data.

3. **File(s): `web/lib/memba/messaging/email_delivery_dispatcher.ex`, `web/lib/memba/messaging/projectors/email_delivery.ex`**
   - **Smell:** Business dispatch depends on a PubSub/read-model-change nudge.
   - **Why it may need judgement:** The plan explicitly accepts no startup sweep, no periodic sweep, and manual intervention if nudges are missed. That is acceptable for this slice, but PubSub is a fragile trigger for durable business work unless paired with recovery/sweeping.
   - **Potential follow-up:** Decide whether this should remain a one-off pragmatic pattern or be formalized/hardened with a durable dispatcher sweep/job in a later iteration.

4. **File(s): `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
   - **Smell:** Deliveries can likely remain indefinitely in `dispatching` if the process crashes after claim but before marking `sent`/`failed`.
   - **Why it may need judgement:** The plan explicitly accepts ambiguity after provider acceptance, but stale `dispatching` before or during provider dispatch is a separate operational state operators will need to understand.
   - **Potential follow-up:** Add an internal “requeue stale dispatching delivery” API, or include `dispatching_started_at`/timeout handling in a future retry/sweep iteration.

5. **File(s): `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
   - **Smell:** Single GenServer dispatch path serializes provider calls.
   - **Why it may need judgement:** This is simple and appropriate for a first handoff boundary, but it can become a throughput bottleneck for large clubs or bulk sends.
   - **Potential follow-up:** If volume grows, use supervised tasks or a job system while preserving the same claim/update lifecycle.

6. **File(s): `web/lib/memba/messaging.ex`, `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
   - **Smell:** Messaging context may still mix command orchestration, read-model queries, delivery provider infrastructure, and retry/dispatch APIs.
   - **Why it may need judgement:** The plan already lists large application-service modules as a follow-up concern. This iteration improves the boundary but may not fully isolate provider infrastructure from the context API.
   - **Potential follow-up:** Extract a focused delivery dispatch/service module and keep `Memba.Messaging` as a thinner facade.

7. **File(s): provider adapters / dispatcher request-building code**
   - **Smell:** Provider-level idempotency does not appear to be enforced.
   - **Why it may need judgement:** The plan explicitly accepts possible duplicate sends after provider acceptance and before marking `sent`. That is fine for this slice, but it is user-visible if it happens in production.
   - **Potential follow-up:** Use `delivery_id` as a provider idempotency/custom metadata key where Postmark/Resend support it.

8. **File(s): staff/member delivery presentation files**
   - **Smell:** New infrastructure statuses may leak into user-facing presentation if labels are shared too broadly.
   - **Why it may need judgement:** The plan wanted member-facing screens to hide/soften infrastructure detail while staff/operator views may show exact diagnostics.
   - **Potential follow-up:** Keep separate member-facing and staff-facing status-label helpers if they are not already separate.

## Suggested fixes

Recommended non-blocking polish before or soon after merge:

1. Add `Logger` instrumentation to dispatcher claim/success/failure/retry paths.
2. Mark dispatcher-only context functions as `@doc false` or move them into the dispatcher/collaborator module.
3. Add exception-to-failed-delivery handling around provider calls, with clear error logging.
4. Centralize status vocabulary and, if safe, back it with a DB check constraint.
5. Create a follow-up ticket for stale `dispatching` recovery and/or durable sweep semantics.

No feature-file changes are recommended.

## Validation notes

- `dev ci` passed successfully.
- Full browser acceptance suite passed:
  - 82 scenarios
  - 493 steps
- The implementation evidence indicates coverage around:
  - pending email delivery creation
  - dispatcher claiming
  - provider success path
  - provider failure path
  - failed-delivery diagnostics
  - manual retry
  - fake/selective-failure provider seams
  - inbound club-message flow using the same delivery path
- No blocking acceptance-criteria gap was identified.
- Manual checks still worth doing operationally:
  1. Send a local/dev club message with the fake provider and observe `pending → dispatching → sent`.
  2. Force provider failure and confirm `failed`, `attempt_count`, and latest error/detail are persisted.
  3. Retry a failed delivery and confirm it returns to the dispatch path without creating duplicate local delivery records.
  4. Inspect member-facing and staff-facing delivery views for appropriate status wording.