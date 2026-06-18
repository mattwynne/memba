# Email delivery handoff boundary

Date: 2026-06-17
Status: draft

## Goal

Make outbound club-message email handoff explicit and replay-safe by separating the event-sourced message-send decision from the external email-provider side effect.

After this iteration, `Memba.Messaging.send_club_message/2` should no longer commit `MessageSent` / `EmailDeliveryCreated` events and then synchronously call the provider in a way that can return `{:error, reason}` after the event stream already records the message as sent. Instead, the system should record provider handoff intent/state in an internal boundary that can be observed, tested, and safely retried without replaying domain events into duplicate emails.

## Background / Context

A design review against the CQRS, DDD, RDD, and event-sourcing reference pages found a strong foundation: Membership and Messaging are separate Commanded contexts, commands/events use domain language, and read models are projected. The highest-risk drift is that `Memba.Messaging.send_club_message/2` mixes a domain command with real-world email delivery side effects:

1. resolve recipients from Membership projections,
2. dispatch `SendMessage`, which commits message and delivery-created events,
3. synchronously call the configured email provider for each recipient,
4. return an error if provider delivery fails.

That sequence can make the command result look failed after the source-of-truth event stream already says the message and delivery records exist. It also leaves provider handoff hidden inside application-service control flow rather than as a named collaboration with explicit retry/idempotency semantics.

This iteration is a technical/engineering slice: it keeps user-facing message behaviour the same while making the delivery side-effect boundary safer and clearer.

## Related Problems

- [CQRS/event-sourcing design drift is concentrating orchestration, read-model checks, and side effects in application services](../../problems/2026-06-17-cqrs-event-sourcing-design-drift.md) — partially addresses the most important finding by extracting/naming the email-provider handoff boundary for outbound club messages. It deliberately leaves other application-service bloat and projection-backed policies for later iterations.
- [The deprecated "opened" email delivery status should be obliterated](../../problems/2026-06-17-obliterate-opened-email-delivery-status.md) — leaves unresolved. This iteration should avoid expanding any `opened` compatibility code and should not make the handoff boundary depend on deprecated delivery-status concepts.

## Scope

### In scope

- Design and implement a small internal email handoff boundary for outbound club-message deliveries.
- Preserve the existing public behaviour for successful browser-composed and inbound-composed club messages.
- Ensure provider failure after event commit is represented consistently: either as a handoff failure state/result or a retryable internal job/outbox row, not as a misleading failed `send_club_message/2` result for an already-committed message.
- Keep provider calls outside aggregate replay and projector replay paths.
- Add focused automated tests for successful handoff, provider failure, partial recipient failure, and duplicate/retry safety.
- Update module names/contracts so the responsibility split is visible from code.
- Keep existing delivery-status semantics (`sent`, `delivered`, `delayed`, `bounced`, `spam_complaint`) unchanged.

### Out of scope

- Removing the deprecated `opened` status (iteration 035 / separate problem note).
- Introducing a full background job system unless a minimal in-process/outbox-style boundary is needed for this slice.
- Changing member/staff UI copy or delivery-status presentation.
- Redesigning inbound email acceptance/rejection workflow beyond adapting to the new outbound handoff API when it sends a club message.
- Refactoring all of `Memba.Messaging` or `Memba.Membership` application-service bloat.
- Solving every cross-aggregate policy consistency concern identified by the design review.

## Iteration Type

Technical/engineering.

There is no intended new user-observable behaviour. The slice improves the internal CQRS/event-sourcing boundary around outbound email side effects while keeping message sending and delivery-status surfaces working as they do now.

## Acceptance Scenarios / Feature Files

Not applicable.

This is an internal architectural slice with no new business rule or user-facing workflow. Existing acceptance scenarios for club-message sending and delivery-status views should continue to pass. Coverage should be added or updated in ExUnit tests around `Memba.Messaging`, the provider boundary, and any new handoff module/read model.

## Acceptance Criteria

- `Memba.Messaging.send_club_message/2` has a clear result contract that does not report the domain send command as failed after the message event stream has committed successfully.
- External provider delivery is performed by a named collaborator (for example `Memba.Messaging.EmailDeliveryHandoff` or similarly explicit module), not inline inside the main Messaging application service.
- Provider handoff failures are observable and testable without lying about the committed message state.
- A provider failure for one recipient cannot cause silent ambiguity about earlier recipients in the same message.
- Retrying handoff does not create a second message stream or duplicate `EmailDeliveryCreated` events.
- Event/projector replay does not call external providers.
- Existing successful send flows still create message and email-delivery read models and hand off email requests to the configured provider.
- The implementation includes tests for:
  - successful handoff for all recipients,
  - provider failure before any recipient is accepted,
  - provider failure after at least one recipient has been accepted,
  - safe duplicate/retry of a handoff for an already-created delivery,
  - inbound club-message acceptance still sends through the same outbound handoff boundary.
- `dev check` passes.

## Open Business Decisions

None known.

## Implementation Plan

1. Inspect current outbound send paths and tests:
   - `Memba.Messaging.send_club_message/2`, `deliver_to_provider/1`, and `email_delivery_request/3`.
   - browser compose and inbound club-message acceptance callers.
   - fake/local/Postmark/Resend provider test seams.
2. Define the smallest explicit handoff contract. Prefer a module that accepts committed message/delivery data and returns a structured handoff result such as `{:ok, summary}` or `{:error, {:handoff_failed, summary}}`, where the summary names which delivery IDs were attempted/succeeded/failed.
3. Move provider-specific iteration over recipients out of `Memba.Messaging` into the named handoff collaborator.
4. Adjust `send_club_message/2` so command dispatch and provider handoff results are not conflated. The caller should be able to know the `message_id`/dispatch result even when handoff fails.
5. If needed, add a small Ecto-backed handoff/read model or status field to make failure/retry observable. Keep it minimal and do not turn this slice into a full background job platform.
6. Ensure idempotency/retry safety at the handoff boundary. If the provider adapter lacks provider-level idempotency, record enough local state to avoid sending the same delivery twice during a retry in this application.
7. Route inbound accepted club messages through the same handoff contract without duplicating side-effect code.
8. Remove obsolete inline helper functions from `Memba.Messaging` or leave thin delegators only where necessary for compatibility.
9. Add/update focused tests for the acceptance criteria above.
10. Run `dev check` and fix any regressions.

## Open Technical Decisions

- Whether the minimal safe boundary should be:
  - an extracted synchronous collaborator with structured results only, or
  - a tiny persisted outbox/handoff table with retry state.
- Whether provider adapters already expose enough idempotency key support to prevent duplicate sends per `delivery_id`, or whether Memba must persist local sent/attempted state before retry is safe.
- Whether handoff failure should update an existing read model or a new internal operational read model. Avoid overloading recipient delivery status (`sent/delivered/delayed/bounced/spam_complaint`) with provider-handoff implementation details unless a deliberate vocabulary decision is made.

## New Capability

Developers/operators can reason about outbound email provider handoff as a named, testable boundary separate from message-domain event sourcing. Provider failures after a message is committed are explicit and retryable/observable instead of being hidden behind a misleading command error.

## Validation Plan

- Run targeted tests around messaging send, provider adapters/fakes, and inbound club-message acceptance during implementation.
- Run `dev check` before declaring the iteration complete.
- Manually inspect a local/dev send flow with the fake provider to confirm existing message and delivery views still populate.
- Manually or through tests simulate provider failure and confirm the message stream/read model state and handoff result/state are consistent.

## Risks / Follow-ups

- A truly robust handoff boundary may want a full outbox/background worker in a later iteration. Keep this slice small but avoid designs that make that harder.
- Existing callers may assume `send_club_message/2` returns only `:ok`/error-style outcomes; changing the result contract may require careful compatibility updates in LiveViews, controllers, and tests.
- If retries are introduced without provider idempotency or local sent-state recording, duplicate emails could be sent. Treat duplicate-prevention as part of the acceptance criteria.
- Other design-review findings remain: large application-service modules, Membership projection-backed policy preflights, onboarding conversion orchestration, and deprecated `opened` compatibility cleanup.
