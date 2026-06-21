# Iteration 038 Review: Email Delivery Handoff Boundary

## Decision: ACCEPT

## Confidence: Medium

The implementation appears to satisfy the iteration goal and the plan-conformance gate has already passed. The new async email delivery lifecycle decouples `send_club_message/2` command acceptance from provider availability, creates `EmailDelivery` records in a dispatchable state, uses a supervised dispatcher, records provider failures with diagnostics, and provides an internal/manual retry path.

Confidence is medium rather than high because the remaining concerns are architectural/code-health trade-offs around projection determinism, PubSub-triggered work, and operational recovery. Those are real smells, but they were either explicitly selected or explicitly deferred by the iteration plan, and I do not see a merge-blocking ADR or behavioural violation in the supplied evidence.

One workflow note: the review-repair stage claimed to apply bounded fixes, but `verify_review_repair` showed no working-tree diff change since repair started. I therefore reviewed the committed implementation as-is, not assuming those claimed repair changes exist.

## ADR conformance: PASS

The plan text supplied does not cite a specific ADR. Based on the supplied implementation evidence and the review context, I did not identify a conflict with accepted architectural direction.

The implementation remains broadly consistent with CQRS/event-sourced boundaries for this slice:

- command acceptance is no longer coupled to synchronous provider delivery;
- provider interaction is moved behind an explicit read-model lifecycle;
- `EmailDelivery` records model handoff state and diagnostics;
- the dispatcher is supervised and nudged by read-model changes, as the plan explicitly directed.

There are event-sourcing and responsibility-design smells, especially projection-time lookups of current member state and PubSub as a business-work trigger, but the plan explicitly chose existing `EmailDelivery` records, a PubSub-nudged dispatcher, and no automatic sweep/retry mechanism for this iteration. Without a cited ADR forbidding that pattern, those are non-blocking design follow-ups.

## ADR violations

1. None identified from the supplied plan, evidence, and dev-check output.

## Blocking issues

1. None.

The previously synthesized “blockers” are better classified as bounded-safe polish/hardening:

- dispatcher observability;
- provider exception normalization;
- centralized status vocabulary.

They are worthwhile, but I do not see evidence that they are required to satisfy the iteration plan or an accepted ADR before merge.

## Bounded-safe fixes

1. **Add or verify structured dispatcher logging**
   - File: `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - Add structured log entries around:
     - PubSub/read-model nudge received;
     - delivery claim attempted/succeeded/skipped;
     - provider dispatch succeeded;
     - provider dispatch failed;
     - manual retry requested/requeued.
   - Include `delivery_id`, `message_id`, current/new status, provider module/name, attempt count, and sanitized error detail.
   - This is low-risk observability polish for the new async boundary.

2. **Normalize unexpected provider exceptions into failed-delivery diagnostics**
   - File: `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - Provider adapters should return `:ok` or `{:error, reason}`, but the dispatcher boundary can defensively rescue unexpected provider exceptions, log them, and persist the delivery as `failed` with `latest_error` / `latest_error_detail`.
   - This reduces the chance of deliveries remaining stuck in `dispatching` due to an unhandled provider crash.

3. **Centralize email delivery status vocabulary if not already done in the committed diff**
   - Files likely involved:
     - `web/lib/memba/messaging/projections/email_delivery.ex`
     - `web/lib/memba/messaging/projectors/email_delivery.ex`
     - `web/lib/memba/messaging/email_delivery_dispatcher.ex`
     - delivery status constraint tests
   - Keep lifecycle statuses and preserved provider/webhook statuses in one shared vocabulary:
     - lifecycle: `pending`, `dispatching`, `sent`, `failed`;
     - webhook/provider statuses: existing values such as `delivered`, `bounced`, `opened`, etc.
   - This avoids drift between schema validation, DB constraints, dispatcher clauses, UI labels, and tests.

4. **Mark dispatcher-only provider/request helpers as internal or move them behind a focused boundary**
   - File: `web/lib/memba/messaging.ex`
   - If functions such as `deliver_to_provider/1` or request-building helpers remain on the public `Memba.Messaging` context mainly for dispatcher use, mark them `@doc false`, add typespecs, or move them into `EmailDeliveryDispatcher` / a focused collaborator.
   - This preserves behaviour while reducing accidental coupling to provider infrastructure.

5. **Add typespecs for new public/internal APIs**
   - Files:
     - `web/lib/memba/messaging.ex`
     - `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - Good candidates:
     - `retry_failed_delivery/1`;
     - manual dispatch/retry entry points;
     - provider request-building functions;
     - claim/update helpers if public.
   - This is small maintainability polish around the new boundary.

6. **Keep DB/schema status constraints synchronized with the shared vocabulary**
   - Files:
     - email delivery migration/schema;
     - `web/test/memba/messaging/email_delivery_status_constraints_test.exs` or equivalent.
   - If a DB check constraint exists, keep a regression test proving it accepts the full intended status vocabulary, including historical/provider webhook statuses.
   - If only schema validation exists, that is acceptable under the plan, but DB-level protection can be a safe follow-up once the vocabulary is stable.

## Judgement-worthy non-blocking code-health findings

1. **File(s): `web/lib/memba/messaging/projectors/email_delivery.ex`**
   - **Smell:** The `EmailDelivery` projector appears to derive recipient email/address data by querying current member state.
   - **Why it may need human judgement:** In event-sourced systems, projections are healthiest when deterministic from event data. Querying current state means delayed projection or replay can produce different delivery rows if member contact data changes after the message event.
   - **Why not blocking:** The iteration plan explicitly chose to use existing `EmailDelivery` records and did not require event enrichment or a new delivery-request event.

2. **File(s): `web/lib/memba/messaging/projectors/email_delivery.ex`**
   - **Smell:** Missing or blank member email may result in no `EmailDelivery` record being created.
   - **Why it may need human judgement:** The domain may show a message as accepted/sent while operators have no delivery row explaining why no provider dispatch happened.
   - **Potential follow-up:** Decide whether missing recipient contact data should:
     - prevent the message command;
     - create an explicit failed/undeliverable delivery;
     - be captured in the event payload as immutable delivery context.

3. **File(s): `web/lib/memba/messaging/projectors/email_delivery.ex`, `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
   - **Smell:** Provider dispatch depends on a PubSub/read-model-change nudge.
   - **Why it may need human judgement:** PubSub is not durable work scheduling. If a notification is missed while a delivery remains `pending`, no automatic retry/startup/periodic sweep exists in this slice.
   - **Why not blocking:** The plan explicitly accepted this operational trade-off and deferred automatic sweeps/retries.

4. **File(s): `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
   - **Smell:** A delivery can remain indefinitely in `dispatching` if the dispatcher crashes after claim but before marking `sent` or `failed`.
   - **Why it may need human judgement:** This creates an operational recovery state distinct from the already-accepted “provider accepted but app crashed before marking sent” ambiguity.
   - **Potential follow-up:** Add a manual stale-dispatching recovery API or later sweep/timeout process.

5. **File(s): `web/lib/memba/messaging/email_delivery_dispatcher.ex`**
   - **Smell:** Dispatch appears to be serialized through a single supervised dispatcher process.
   - **Why it may need human judgement:** Simple and probably appropriate for this slice, but slow provider calls can accumulate latency for larger clubs or bulk sends.
   - **Potential follow-up:** Preserve claim/update semantics while moving provider calls to supervised tasks or a durable job system if volume requires it.

6. **File(s): `web/lib/memba/messaging.ex`**
   - **Smell:** The messaging context may still mix command orchestration, read-model access, retry APIs, request building, and provider infrastructure.
   - **Why it may need human judgement:** This iteration improves the critical behaviour boundary, but the context can continue drifting toward a large application-service module.
   - **Potential follow-up:** Extract a focused delivery handoff/request-building module and keep `Memba.Messaging` as a thin facade.

7. **File(s): provider adapters and dispatcher/request-building code**
   - **Smell:** Provider-level idempotency remains deferred.
   - **Why it may need human judgement:** Duplicate provider sends remain possible if the provider accepts an email and the app crashes before the delivery is marked `sent`.
   - **Why not blocking:** The plan explicitly accepted best-effort duplicate prevention for this slice.
   - **Potential follow-up:** Pass `delivery_id` as provider metadata/idempotency where Postmark/Resend support it.

8. **File(s): member/staff delivery presentation helpers or templates**
   - **Smell:** Infrastructure statuses such as `pending`, `dispatching`, and `failed` can leak into member-facing copy if status-label helpers are shared too broadly.
   - **Why it may need human judgement:** Staff/operator views may need exact diagnostics; member-facing views should hide or soften infrastructure detail.
   - **Potential follow-up:** Keep separate presentation helpers for member-facing delivery status and operator diagnostics.

## Suggested fixes

Recommended non-blocking polish before or shortly after merge:

1. Add structured logging to the dispatcher claim, success, failure, retry, and skipped-claim paths.
2. Defensively convert unexpected provider exceptions into persisted failed-delivery diagnostics.
3. Centralize and test the complete email delivery status vocabulary.
4. Mark dispatcher-only provider/request helpers as internal or move them into a focused collaborator.
5. Add typespecs for new retry/dispatch/provider-boundary functions.
6. Create follow-up work for:
   - stale `dispatching` recovery;
   - durable pending-delivery sweep/retry semantics;
   - projection determinism / event enrichment for immutable recipient data;
   - provider-level idempotency using `delivery_id`;
   - operator playbook for stuck pending/dispatching deliveries.

## Validation notes

- `dev ci` / dev check passed before review.
- Acceptance suite passed:
  - 82 scenarios;
  - 493 steps.
- Unit test count reported as passing:
  - 824 tests;
  - 0 failures.
- Acceptance feature files were not reported as modified.
- Supplied evidence indicates automated coverage around:
  - pending delivery creation;
  - pending → dispatching → sent/failed transitions;
  - provider success path;
  - provider failure path;
  - attempt count and latest error/detail persistence;
  - manual failed-delivery retry;
  - fake/selective-failure provider seams;
  - inbound club-message flow using the same delivery path.
- Useful manual/operator checks after merge:
  1. Send a local/dev club message with the fake provider and observe `pending → dispatching → sent`.
  2. Force provider failure and confirm `failed`, incremented `attempt_count`, and persisted diagnostics.
  3. Retry a failed delivery and confirm it re-enters dispatch without duplicate local delivery records.
  4. Inspect member-facing and staff/operator delivery views for appropriate wording and diagnostics.