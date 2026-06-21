# Iteration 038 Review: Email Delivery Handoff Boundary

## Decision: ACCEPT

## Confidence: Medium

The implementation appears to deliver the intended handoff boundary: message acceptance is no longer synchronously coupled to provider availability, `EmailDelivery` records now model an explicit dispatch lifecycle, provider failures are persisted as delivery diagnostics, and a manual/internal retry path exists. The completed `dev ci`/dev check passed, including the browser acceptance suite.

Confidence is medium because the remaining concerns are mostly architectural/code-health judgement calls around projection determinism, PubSub-triggered durable work, and operational recovery semantics rather than clear behavioural defects.

## ADR conformance: PASS

The iteration plan does not cite a specific ADR. Based on the supplied implementation evidence and the plan’s explicit design decisions, I did not identify a binding ADR conflict.

The implementation is broadly consistent with the CQRS/event-sourced direction: command acceptance remains distinct from read-model/provider dispatch, and provider interaction has been moved behind an explicit async lifecycle. Some choices are event-sourcing/code-health smells — especially projection-time member lookups and PubSub as the dispatch trigger — but the plan intentionally selected existing `EmailDelivery` records and a supervised PubSub-nudged dispatcher for this slice. I would not reject on those grounds without a specific accepted ADR forbidding the pattern.

## ADR violations

1. None identified from the available plan and implementation evidence.

## Blocking issues

1. None.

The implementation appears plan-conforming enough to merge. I did not find a substantial missing acceptance criterion, behavioural gap, or unsafe test omission that should require a new implementation pass before merge.

## Bounded-safe fixes

1. **Mark dispatcher-only context helpers as internal or move them behind the dispatcher boundary**
   - File: `web/lib/memba/messaging.ex`
   - If `deliver_to_provider/1` and request-building helpers remain public on `Memba.Messaging` only for dispatcher use, mark them `@doc false`, add typespecs, or move them into `Memba.Messaging.EmailDeliveryDispatcher` / a focused collaborator.
   - This is a low-risk boundary polish that reduces accidental coupling to provider infrastructure.

2. **Add structured dispatcher logging**
   - File: `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - Add `Logger` entries for:
     - delivery claimed
     - claim skipped because status changed
     - provider success
     - provider error
     - failed delivery retried/requeued
   - Include useful fields such as `delivery_id`, `message_id`, provider module, prior/new status, and sanitized error detail.
   - This does not change product behaviour and will help operators understand the new async lifecycle.

3. **Centralize email delivery status vocabulary**
   - Files likely involved:
     - `web/lib/memba/messaging/email_delivery.ex`
     - `web/lib/memba/messaging/email_delivery_dispatcher.ex`
     - `web/lib/memba/messaging/projectors/email_delivery.ex`
     - delivery presentation helpers/tests
   - If statuses are currently repeated as string literals, extract schema-level constants or a small vocabulary helper for lifecycle/provider statuses.
   - This reduces drift between validation, UI labels, dispatcher clauses, tests, and any future DB constraints.

4. **Add a DB check constraint only if the full status vocabulary is already known**
   - File: relevant `email_deliveries` migration.
   - The plan allowed “database constraints or schema validation.” If schema validation already exists, this is not required for merge.
   - A DB constraint would be safe only if it includes all existing and preserved webhook/provider statuses. Avoid hand-copying a partial list that could reject historical or provider-originated states.

5. **Add typespecs for new public/internal retry and dispatch APIs**
   - Files:
     - `web/lib/memba/messaging.ex`
     - `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - Useful candidates include retry APIs, claim/dispatch entry points, and provider request builders.
   - This is small maintainability polish for the new boundary.

## Judgement-worthy non-blocking code-health findings

1. **File(s): `web/lib/memba/messaging/projectors/email_delivery.ex`**
   - **Smell:** The `EmailDelivery` projector appears to query current member state to derive recipient email/address data while handling `MessageSent`.
   - **Why it may need human judgement:** In an event-sourced system, projections are usually healthiest when they are deterministic functions of the event stream. Querying current read-model/domain state introduces temporal coupling: replay or delayed projection can produce different delivery records depending on member email changes, deletion, or projection timing.
   - **Why not blocking:** The iteration plan explicitly chose to use existing `EmailDelivery` records and did not require event enrichment or a new delivery-request event. This may be an accepted pragmatic trade-off for this slice.

2. **File(s): `web/lib/memba/messaging/projectors/email_delivery.ex`**
   - **Smell:** Missing or blank member email can apparently cause the projector to skip creating an `EmailDelivery`.
   - **Why it may need human judgement:** If the domain has recorded `MessageSent`, silently having no local delivery/diagnostic record may make operator reasoning harder: a message appears accepted/sent, but no dispatch attempt or failure record exists.
   - **Potential follow-up:** Decide whether “no deliverable recipient address” should be represented as an explicit failed/undeliverable delivery record, prevented before `MessageSent`, or solved by including recipient delivery data in the event.

3. **File(s): `web/lib/memba/messaging/projectors/email_delivery.ex`, `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
   - **Smell:** Provider dispatch depends on a PubSub/read-model-change nudge.
   - **Why it may need human judgement:** The plan explicitly deferred automatic retry, startup sweeps, and periodic sweeps. That makes PubSub acceptable for this slice, but it is still a fragile trigger for durable business work: if a nudge is missed while a delivery is `pending`, dispatch can stall until manual intervention.
   - **Potential follow-up:** Decide whether this pattern should be codified as a Memba convention, replaced by a durable job/sweep mechanism, or hardened in a later iteration.

4. **File(s): `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
   - **Smell:** Deliveries can remain indefinitely in `dispatching` if the process crashes after claim but before marking `sent` or `failed`.
   - **Why it may need human judgement:** The plan explicitly accepts ambiguity after provider acceptance, but stale `dispatching` before/during provider dispatch is a distinct operational state. Operators need a way to recognize and safely recover it.
   - **Potential follow-up:** Add a manual “requeue stale dispatching delivery” API or a later sweep/timeout process.

5. **File(s): `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
   - **Smell:** Dispatch appears serialized through a single GenServer/process.
   - **Why it may need human judgement:** This is simple and likely appropriate for an initial boundary, but bulk sends or large clubs could experience provider-call latency accumulating linearly.
   - **Potential follow-up:** If volume requires it, preserve the claim/update lifecycle while moving provider calls to supervised tasks or a durable job system.

6. **File(s): `web/lib/memba/messaging.ex`, `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
   - **Smell:** The `Memba.Messaging` context may still carry mixed responsibilities: command orchestration, read-model access, provider request building, dispatch support, and retry APIs.
   - **Why it may need human judgement:** The iteration improves the most important coupling by removing synchronous provider delivery from `send_club_message/2`, but the context can still drift toward an application-service god module.
   - **Potential follow-up:** Extract a focused delivery handoff/request-building module and keep `Memba.Messaging` as a thin facade.

7. **File(s): provider adapters and dispatcher request-building code**
   - **Smell:** Provider-level idempotency does not appear to be enforced.
   - **Why it may need human judgement:** The plan explicitly accepts possible duplicate sends after provider acceptance and before marking `sent`. That is fine for this slice but remains user-visible if it happens in production.
   - **Potential follow-up:** Use `delivery_id` as provider metadata/idempotency where Postmark/Resend support it.

8. **File(s): member/staff delivery presentation helpers or templates**
   - **Smell:** New infrastructure statuses such as `pending`, `dispatching`, and `failed` can leak into user-facing language if staff/member labels share helpers too broadly.
   - **Why it may need human judgement:** The plan wanted member-facing screens to hide or soften infrastructure detail while staff/operator views may show exact diagnostics.
   - **Potential follow-up:** Keep separate presentation helpers for member-facing status labels versus operator diagnostics.

## Suggested fixes

Recommended polish before or shortly after merge:

1. Add structured logging to dispatcher claim/success/failure/retry paths.
2. Mark dispatcher-only context functions as `@doc false` or move them to a focused dispatch/request-building module.
3. Centralize the status vocabulary to avoid string-literal drift.
4. Add typespecs for the new retry/dispatch/public boundary functions.
5. Create follow-up work for:
   - stale `dispatching` recovery,
   - durable pending-delivery sweep/retry semantics,
   - projection determinism / event enrichment for delivery recipient data,
   - provider-level idempotency using `delivery_id`.

## Validation notes

- `dev ci` / dev check passed before review.
- Full browser acceptance suite passed:
  - 82 scenarios
  - 493 steps
- The supplied evidence indicates automated coverage around:
  - pending delivery creation,
  - dispatcher claim logic,
  - provider success path,
  - provider failure path,
  - attempt count and latest error/detail persistence,
  - manual failed-delivery retry,
  - fake/selective-failure provider seams,
  - inbound club-message flow using the same delivery path.
- No feature-file changes are recommended.
- Useful manual/operator checks after merge:
  1. Send a local/dev club message with the fake provider and observe `pending → dispatching → sent`.
  2. Force provider failure and confirm `failed`, incremented attempt count, and persisted latest error/detail.
  3. Retry a failed delivery and confirm it re-enters dispatch without duplicate local delivery records.
  4. Inspect member-facing and staff/operator delivery views for appropriate status wording and diagnostics.