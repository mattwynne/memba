# Async email delivery dispatch

Date: 2026-06-19
Status: ready

## Goal

Make outbound club-message email delivery dispatch explicit, asynchronous, observable, and retryable without making the user-facing message-send command depend on synchronous email-provider availability.

After this iteration, `Memba.Messaging.send_club_message/2` should accept and record the message and its recipient email deliveries, then return success without calling the external email provider inline. Per-recipient `EmailDelivery` records should start as `pending` work, be dispatched by an OTP-supervised dispatcher outside aggregate/projector replay, and move through an honest operational lifecycle: `pending` → `dispatching` → `sent` or `failed`.

## Background / Context

A design review against the CQRS, DDD, RDD, and event-sourcing reference pages found a strong foundation: Membership and Messaging are separate Commanded contexts, commands/events use domain language, and read models are projected. The highest-risk drift is that `Memba.Messaging.send_club_message/2` currently mixes a domain command with real-world email delivery side effects:

1. resolve recipients from Membership projections,
2. dispatch `SendMessage`, which commits `MessageSent` and `EmailDeliveryCreated` events,
3. synchronously call the configured email provider for each recipient,
4. return an error if provider dispatch fails.

That sequence can make the command result look failed after the source-of-truth event stream already says the message and delivery records exist. It can also leave a mixed real-world outcome: earlier recipients may have been accepted by the provider while later recipients failed. Retrying the whole command risks duplicate domain events or duplicate emails.

The modelling issue is sharper in the current `EmailDelivery` projection: `EmailDeliveryCreated` currently creates records with status `sent`, even though provider dispatch has not happened yet. The improved model is to treat `EmailDelivery` itself as the per-recipient operational dispatch record. `EmailDeliveryCreated` creates `pending` delivery work; a separate dispatcher advances that work once the provider accepts or rejects the request.

This iteration is a technical/engineering slice: it keeps the user-facing message-send behaviour the same while making the internal dispatch lifecycle truthful and safe enough to retry manually. We considered renaming `MessageSent`, but deliberately leave event-vocabulary migration out of this slice; the clearer `EmailDelivery` lifecycle reduces the immediate ambiguity without changing historic event compatibility.

## Related Problems

- [CQRS/event-sourcing design drift is concentrating orchestration, read-model checks, and side effects in application services](../../problems/2026-06-17-cqrs-event-sourcing-design-drift.md) — partially addresses the most important finding by removing synchronous provider dispatch from `Memba.Messaging.send_club_message/2` and introducing an explicit async dispatch boundary for outbound club-message emails. It deliberately leaves other application-service bloat, projection-backed policies, and multi-aggregate workflow concerns for later iterations.
- [The deprecated "opened" email delivery status should be obliterated](../../problems/2026-06-17-obliterate-opened-email-delivery-status.md) — leaves unresolved. This iteration should avoid expanding any `opened` compatibility code and should not make async dispatch depend on deprecated delivery-status concepts.

## Scope

### In scope

- Use the existing `EmailDelivery` projection/read model as the per-recipient async dispatch record.
- Change newly-created email deliveries from initial status `sent` to initial status `pending`.
- Add the operational dispatch lifecycle `pending` → `dispatching` → `sent` or `failed`.
- Keep existing provider/webhook outcome statuses available after provider acceptance: `delivered`, `delayed`, `bounced`, `spam_complaint`.
- Remove synchronous provider calls from `Memba.Messaging.send_club_message/2`; successful command dispatch should return success once Memba has accepted and recorded the message/delivery work.
- Add an OTP-supervised in-app dispatcher, such as `Memba.Messaging.EmailDeliveryDispatcher`, without introducing an external job library.
- Have the dispatcher subscribe to the existing `Memba.ReadModelChanges` Phoenix PubSub topic as a nudge when committed read-model changes create pending delivery work.
- Ensure provider calls happen only in the dispatcher/manual retry path, never during aggregate replay or projector replay.
- Persist retry/diagnostic fields on `EmailDelivery`, including at least attempt count and latest provider error/detail; useful timestamps such as dispatch attempt time, sent time, and failure time are allowed.
- Provide an internal/manual retry API for failed deliveries. A staff retry UI is not in scope.
- Keep member-facing surfaces from exposing alarming infrastructure detail; existing staff/operator diagnostics may show exact `pending`, `dispatching`, `failed`, and latest error information where appropriate.
- Add focused automated tests for message acceptance, async dispatch, provider failure, manual retry, and inbound club-message acceptance using the same dispatch path.

### Out of scope

- A full external background job system such as Oban.
- Automatic retry scheduling, periodic sweeping, or startup sweeping for pending/failed deliveries.
- A staff UI button or workflow for retrying failed deliveries.
- Renaming historic or current domain events such as `MessageSent`.
- Removing the deprecated `opened` status (iteration 035 / separate problem note).
- Changing member/staff copy beyond minimal status presentation needed to avoid broken screens.
- Redesigning inbound email acceptance/rejection workflow beyond adapting accepted inbound club messages to the async dispatch model.
- Refactoring all of `Memba.Messaging` or `Memba.Membership` application-service bloat.
- Solving every cross-aggregate policy consistency concern identified by the design review.

## Iteration Type

Technical/engineering.

There is no intended new user-observable business behaviour. The user-facing send request still succeeds when Memba accepts and records the message. The slice improves the internal CQRS/event-sourcing boundary around outbound email side effects and makes dispatch state truthful and observable.

## Acceptance Scenarios / Feature Files

Not applicable.

This is an internal architectural slice with no new business rule or stakeholder-facing workflow. Existing acceptance scenarios for club-message sending, inbound club-message acceptance, and delivery-status views should continue to pass. Coverage should be added or updated in ExUnit tests around `Memba.Messaging`, `EmailDelivery` projection/status transitions, the dispatcher, provider adapters/fakes, and manual retry.

## Acceptance Criteria

- `Memba.Messaging.send_club_message/2` no longer calls `EmailDeliveryProvider.deliver/1` or any provider adapter synchronously.
- `send_club_message/2` returns success after the message command succeeds and Memba has accepted/recorded the message work; provider dispatch failure is not reported to the sender as though the message command failed.
- `EmailDeliveryCreated` projects an `EmailDelivery` with status `pending`, not `sent`.
- The system supports these `EmailDelivery` statuses for the dispatch lifecycle: `pending`, `dispatching`, `sent`, `failed`.
- Existing provider/webhook statuses continue to work after provider acceptance: `delivered`, `delayed`, `bounced`, `spam_complaint`.
- A supervised dispatcher process is started under the application supervision tree.
- The dispatcher subscribes to `Memba.ReadModelChanges.topic()` and reacts to committed relevant changes by looking for pending email deliveries to dispatch.
- Provider calls are performed by the dispatcher/manual retry path only, outside aggregate replay and projector replay.
- The dispatcher claims a pending delivery by marking it `dispatching` before calling the provider.
- On provider acceptance, the dispatcher marks the delivery `sent`.
- On provider error, the dispatcher marks the delivery `failed`, increments/persists attempt count, and stores the latest provider error/detail for diagnostics.
- Manual/internal retry can retry failed deliveries without creating a second message stream or duplicate `EmailDeliveryCreated` events.
- Retrying a failed delivery increments attempt count and either moves it to `sent` on success or leaves/returns it to `failed` with the latest error on failure.
- A provider failure for one recipient does not prevent other pending deliveries for the same message from being dispatched.
- Member-facing views do not expose raw infrastructure failure detail in a way that tells the sender “our provider is broken”; staff/operator diagnostics may show exact failed dispatch status and latest error.
- Accepted inbound club-message emails use the same async dispatch path as browser-composed club messages.
- The implementation includes tests for:
  - browser-composed message acceptance creates `pending` email deliveries and returns success without synchronous provider delivery,
  - dispatcher turns pending deliveries into `sent` when the provider accepts them,
  - dispatcher turns provider errors into `failed` deliveries with attempt count and latest error,
  - partial recipient failure is represented per delivery while other recipients can still be dispatched,
  - manual retry of a failed delivery succeeds without new message/delivery-created events,
  - inbound club-message acceptance creates pending deliveries and dispatches through the same dispatcher,
  - replay/projector paths do not call external providers.
- `dev check` passes.

## Open Business Decisions

None known.

## Implementation Plan

1. Inspect current outbound send paths and tests:
   - `Memba.Messaging.send_club_message/2`, `deliver_to_provider/1`, and `email_delivery_request/3`.
   - browser compose and inbound club-message acceptance callers.
   - `Memba.Messaging.Projectors.EmailDelivery` and related member/staff delivery projections.
   - fake/local/Postmark/Resend provider test seams.
2. Update the `EmailDelivery` projection/read model so newly created records start with status `pending` and can store dispatch diagnostics such as attempt count, latest error/detail, and useful timestamps.
3. Add database constraints or schema validation for the expanded status vocabulary where practical, preserving existing webhook statuses.
4. Introduce a named dispatch module/process, probably `Memba.Messaging.EmailDeliveryDispatcher`, under the application supervision tree.
5. Make the dispatcher subscribe to `Memba.ReadModelChanges.topic()` and treat relevant `EmailDeliveryCreated`/EmailDelivery projection changes as a nudge to dispatch pending email deliveries.
6. Implement claiming logic that moves a pending delivery to `dispatching` before provider delivery, avoiding two dispatcher invocations claiming the same pending delivery concurrently.
7. Move request-building/provider-call logic out of `Memba.Messaging` into the dispatcher or a focused collaborator used by the dispatcher.
8. On provider success, update the delivery to `sent`; on provider error, update it to `failed`, increment attempt count, and persist the latest error/detail.
9. Remove the synchronous provider call from `send_club_message/2`; keep its success contract tied to command acceptance/recording, not provider availability.
10. Add an internal/manual retry API for failed deliveries. Do not add automatic retries, startup sweeps, periodic sweeps, or staff retry UI in this slice.
11. Adapt accepted inbound club-message flow so it relies on the same pending-delivery projection and dispatcher path.
12. Adjust member-facing and staff/operator delivery presentation only as needed for the new statuses: hide or soften infrastructure detail on member-facing screens, while allowing staff/operator diagnostics to show exact status/error.
13. Add/update focused tests for the acceptance criteria above.
14. Run `dev check` and fix any regressions.

## Open Technical Decisions

None known.

The plan intentionally decides the previously-open design choices:

- Use existing `EmailDelivery` records rather than a separate handoff/outbox table.
- Use `pending`, `dispatching`, `sent`, and `failed` as the pre/post-provider dispatch lifecycle.
- Use a supervised OTP dispatcher and Phoenix PubSub read-model-change nudges.
- Provide manual/internal retry only; automatic retry is a follow-up.
- Do not rename `MessageSent` in this slice.

## New Capability

Developers/operators can reason about outbound provider dispatch as an explicit, asynchronous lifecycle on each `EmailDelivery`. Provider outages or misconfiguration become observable failed delivery dispatches with retry diagnostics instead of misleading `send_club_message/2` failures after message events have already committed.

## Validation Plan

- Run targeted tests around messaging send, `EmailDelivery` projection/status transitions, dispatcher behaviour, provider adapters/fakes, manual retry, and inbound club-message acceptance during implementation.
- Run `dev check` before declaring the iteration complete.
- Manually inspect a local/dev send flow with the fake provider to confirm message acceptance creates pending deliveries, the dispatcher sends them, and existing message/delivery views still populate.
- Manually or through tests simulate provider failure and confirm the message remains accepted, the affected delivery becomes `failed`, attempt count/latest error are persisted, and manual retry can move it to `sent`.

## Risks / Follow-ups

- There is deliberately no automatic retry, startup sweep, or periodic sweep in this iteration. If the PubSub nudge is missed or the app is down when deliveries are created, an operator/developer must use the internal retry/dispatch API. Automatic retry/sweeping should be a follow-up problem/iteration.
- Best-effort duplicate prevention is acceptable for this slice: retry must not create duplicate domain events or duplicate local delivery records, but a crash after provider acceptance and before marking `sent` can still leave an ambiguous delivery. Strong provider-level idempotency using `delivery_id` may be a later hardening iteration.
- Staff/operator diagnostics may need a later UI polish iteration if raw provider errors are too technical or if retry should become a Staff-facing action.
- Existing callers/tests may assume email deliveries are immediately `sent`; updating them to understand `pending`/async dispatch may touch several tests and projections.
- Other design-review findings remain: large application-service modules, Membership projection-backed policy preflights, onboarding conversion orchestration, and deprecated `opened` compatibility cleanup.
