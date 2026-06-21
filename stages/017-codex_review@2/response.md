# Iteration 038 Review: Email Delivery Handoff Boundary

## Decision: ACCEPT

## Confidence: Medium

The implementation appears to satisfy the iteration goal: outbound provider delivery is now represented as an asynchronous `EmailDelivery` lifecycle, message acceptance is no longer synchronously coupled to provider availability, provider failures are observable, and an internal/manual retry path exists.

Confidence is medium because the remaining concerns are architectural/code-health trade-offs around projection determinism, PubSub-triggered durable work, and operational recovery. Those concerns are real, but they were largely anticipated or explicitly deferred by the plan and do not appear to be merge blockers for this slice.

## ADR conformance: PASS

The plan does not cite a specific ADR. Based on the supplied implementation evidence and review context, I did not identify a conflict with accepted ADRs or with the project’s Commanded/CQRS/event-sourced direction.

The implementation keeps command acceptance distinct from provider dispatch and models delivery state in the read model rather than reintroducing synchronous infrastructure coupling into the command path. Some design choices are event-sourcing smells — especially projection-time member lookups and PubSub-driven dispatch nudges — but the iteration plan explicitly chose this handoff design and deferred stronger durability/recovery mechanisms.

## ADR violations

1. None identified.

## Blocking issues

1. None.

The synthesized “blockers” from the previous review stage are better classified as bounded-safe polish/hardening work, not required behavioural or ADR fixes:
- dispatcher observability,
- provider exception normalization,
- centralized status vocabulary.

The implementation has already passed `dev ci`, including the full acceptance suite, and no substantial acceptance-criteria gap is evident from the supplied evidence.

## Bounded-safe fixes

1. **Make dispatcher/provider boundary more explicit**
   - Files: `web/lib/memba/messaging.ex`, `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - If `deliver_to_provider/1` or request-building helpers remain public on `Memba.Messaging`, mark them `@doc false`, add typespecs, or move them into the dispatcher/a focused delivery collaborator.
   - This preserves behaviour while reducing accidental coupling to provider infrastructure.

2. **Add or verify structured dispatcher logging**
   - File: `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - Useful log points:
     - PubSub nudge received,
     - delivery claimed,
     - claim skipped because status changed,
     - provider dispatch succeeded,
     - provider dispatch failed,
     - retry requested/requeued.
   - Include `delivery_id`, `message_id`, status transition, provider module/name, attempt count, and sanitized error detail.

3. **Normalize unexpected provider exceptions into failed-delivery diagnostics**
   - Files: `web/lib/memba/messaging/email_delivery_dispatcher.ex`, provider test support
   - Provider adapters should normally return `:ok` or `{:error, reason}`, but the dispatcher boundary is a good place to rescue unexpected provider exceptions, log them, and persist the delivery as `failed` with diagnostics.
   - This avoids leaving deliveries indefinitely in `dispatching` due to an unhandled provider crash.

4. **Centralize email delivery status vocabulary if not already fully centralized**
   - Files likely involved:
     - `web/lib/memba/messaging/projections/email_delivery.ex`
     - `web/lib/memba/messaging/projectors/email_delivery.ex`
     - `web/lib/memba/messaging/email_delivery_dispatcher.ex`
     - status constraint tests
   - Keep lifecycle statuses and preserved webhook statuses in one shared vocabulary:
     - lifecycle: `pending`, `dispatching`, `sent`, `failed`
     - webhook/provider statuses: existing historical/provider statuses such as delivered/bounced/opened/etc.
   - This reduces drift between schema validation, DB constraints, dispatcher clauses, tests, and UI labels.

5. **Add typespecs for new public/internal retry and dispatch APIs**
   - Files: `web/lib/memba/messaging.ex`, `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - Good candidates:
     - `retry_failed_delivery/1`,
     - manual dispatch/retry entry points,
     - provider request-building functions,
     - claim/update helpers if public.

6. **Ensure DB/schema status constraints stay synchronized**
   - Files: migration/schema/tests for `email_deliveries`
   - If a DB check constraint exists, keep a test proving it matches the central vocabulary.
   - If only schema validation exists, that is acceptable under the plan, but DB-level protection would be a safe follow-up once the complete status vocabulary is stable.

## Judgement-worthy non-blocking code-health findings

1. **Projection derives recipient data from current state**
   - Files: `web/lib/memba/messaging/projectors/email_delivery.ex`
   - Smell: the `EmailDelivery` projector appears to query current member state to derive recipient email/address data while handling message-sent events.
   - Why it may need judgement: projections in event-sourced systems are healthiest when deterministic from event data. Querying current state means replay or delayed projection can produce different delivery records if member email/address data changes after the event.

2. **Missing/blank member email may silently skip delivery creation**
   - Files: `web/lib/memba/messaging/projectors/email_delivery.ex`
   - Smell: when no usable recipient email exists, the system may create no `EmailDelivery` record rather than an explicit failed/undeliverable diagnostic.
   - Why it may need judgement: the domain may show a message as accepted/sent while operators have no local delivery record explaining why no provider dispatch happened.

3. **Business dispatch depends on PubSub/read-model-change nudges**
   - Files: `web/lib/memba/messaging/projectors/email_delivery.ex`, `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - Smell: pending delivery dispatch depends on a best-effort PubSub notification.
   - Why it may need judgement: PubSub is not durable work scheduling. The plan explicitly deferred startup sweeps, periodic sweeps, and automatic retries, so this is acceptable for the slice, but it creates operational reliance on manual intervention if a nudge is missed.

4. **Deliveries can remain indefinitely in `dispatching`**
   - File: `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - Smell: if the dispatcher crashes after claiming a delivery but before persisting `sent` or `failed`, the delivery may remain stuck.
   - Why it may need judgement: the plan accepts some ambiguity around provider acceptance, but stale `dispatching` is still an operational state that will need a recovery story.

5. **Single dispatcher process serializes provider calls**
   - File: `web/lib/memba/messaging/email_delivery_dispatcher.ex`
   - Smell: a single GenServer-style dispatcher is simple but can serialize slow HTTP provider calls.
   - Why it may need judgement: this is likely fine for the current slice, but large clubs or bulk sends may eventually need supervised tasks, batching, or a durable job system while preserving claim semantics.

6. **`Memba.Messaging` may still carry mixed responsibilities**
   - File: `web/lib/memba/messaging.ex`
   - Smell: the context appears to include command orchestration, read-model queries, retry APIs, and some provider/request-building infrastructure.
   - Why it may need judgement: the iteration improves the most important boundary by removing synchronous provider calls from `send_club_message/2`, but the context can continue drifting into an oversized application-service module.

7. **Provider-level idempotency remains deferred**
   - Files: provider adapters, dispatcher/request-building code
   - Smell: duplicate provider sends remain possible if the provider accepts an email but the app crashes before marking the delivery `sent`.
   - Why it may need judgement: the plan explicitly accepts this edge case for now. Later hardening could pass `delivery_id` as provider metadata/idempotency where supported.

8. **Member-facing and staff-facing delivery status language should remain separate**
   - Files: member/staff delivery presentation helpers/templates
   - Smell: infrastructure statuses such as `pending`, `dispatching`, and `failed` can leak into member-facing UI if shared labels are reused too broadly.
   - Why it may need judgement: staff/operator views may need exact diagnostics, while member-facing views should soften or hide infrastructure detail.

## Suggested fixes

Recommended non-blocking polish before or shortly after merge:

1. Apply the bounded-safe dispatcher hardening:
   - structured logs,
   - provider exception normalization,
   - explicit retry/claim/success/failure metadata.

2. Tighten the provider boundary:
   - move dispatcher-only provider/request helpers out of `Memba.Messaging`, or mark them internal with `@doc false` and typespecs.

3. Centralize and test the email delivery status vocabulary:
   - lifecycle statuses,
   - preserved webhook/provider statuses,
   - schema validation and DB constraints.

4. Create follow-up work for the architectural items:
   - stale `dispatching` recovery,
   - durable pending-delivery sweep or retry process,
   - projection determinism / event enrichment for delivery recipient data,
   - provider idempotency using `delivery_id`,
   - operational playbook for stuck deliveries.

## Validation notes

- `dev ci` passed.
- Acceptance suite passed:
  - 82 scenarios,
  - 493 steps.
- Unit test count reported as passing in prior review context:
  - 824 tests,
  - 0 failures.
- Acceptance feature files were not reported as modified.
- Evidence indicates coverage for:
  - pending delivery creation,
  - pending → dispatching → sent/failed transitions,
  - provider success and provider failure paths,
  - attempt count and latest error/detail persistence,
  - manual failed-delivery retry,
  - fake/selective-failure provider seams,
  - inbound club-message flow using the same delivery path.
- Remaining manual/operator checks worth doing:
  1. Send a local/dev club message with the fake provider and observe `pending → dispatching → sent`.
  2. Force provider failure and confirm `failed`, incremented `attempt_count`, and persisted diagnostics.
  3. Retry a failed delivery and confirm it re-enters dispatch without creating duplicate local delivery records.
  4. Inspect member-facing and staff/operator delivery views for appropriate status wording.