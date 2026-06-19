Now I'll validate the plan against the readiness criteria.

---

# Iteration 038 Plan Validation Report

## Decision: **READY**

## Confidence: **High**

## Blocking Gaps

None.

## Non-blocking Improvements

1. **Dispatcher subscription detail**: The plan says the dispatcher subscribes to `Memba.ReadModelChanges.topic()` and treats "relevant EmailDeliveryCreated/EmailDelivery projection changes" as a nudge. It could be slightly more explicit about what message structure it expects from PubSub (presumably `{:read_model_changed, module, id}` or similar based on Phoenix ecosystem patterns) or whether the dispatcher queries for pending deliveries rather than deriving them from the broadcast payload. This is a minor implementation detail, but naming the expected message pattern in step 5 could help.

2. **Timestamp vocabulary**: Criteria mention "useful timestamps such as dispatch attempt time, sent time, and failure time" but don't specify which timestamps are required vs optional. Implementation plan step 2 repeats "useful timestamps" without concrete field names. Since the criteria already allow latitude ("are allowed"), this is genuinely non-blocking, but being specific would reduce ambiguity.

3. **Manual retry API surface**: Acceptance criteria say "manual/internal retry can retry failed deliveries" and implementation step 10 adds "an internal/manual retry API" but doesn't name a proposed module/function signature (e.g. `Memba.Messaging.retry_delivery(delivery_id)` or similar). This is discoverable during implementation, but a rough signature in the plan would communicate intent more clearly.

## Smallest Viable Iteration

The plan is already **tightly scoped**. The smallest viable slice would be:

- Introduce `pending` status and async dispatch for outbound club messages only (exclude inbound acceptance adaptation temporarily).
- Remove synchronous provider call from `send_club_message/2`.
- Introduce the supervised dispatcher, `pending` → `dispatching` → `sent`/`failed` lifecycle, and basic manual retry.
- Defer provider error detail persistence or multiple timestamp fields to a follow-up if time pressure emerges.

That said, the plan as written is **already minimal and valuable**. The inbound club-message adaptation (step 11) is a natural consistency improvement that prevents two separate dispatch paths. The diagnostic fields (attempt count, latest error) are essential for a usable retry surface. I would **not recommend reducing scope** unless implementation uncovers unforeseen complexity.

## Required Plan Edits

None. The plan is ready for implementation.

## Validation Plan

The validation plan is concrete and sufficient:

- Targeted tests during implementation (send, projection/status transitions, dispatcher, provider adapters/fakes, manual retry, inbound acceptance).
- `dev check` before completion.
- Manual local/dev inspection: confirm pending deliveries, dispatcher sends them, views still work.
- Manual/test provider failure simulation: confirm message accepted, delivery failed, diagnostics persisted, retry works.

This covers happy path, failure cases, replay safety, manual retry, inbound acceptance, and regression prevention.

---

## Detailed Assessment

### 1. Goal Clarity

**✅ Clear and well-articulated.**

The goal states what Memba will do (`send_club_message/2` should accept/record message and deliveries without calling provider inline), why (make dispatch explicit/async/observable/retryable without depending on provider availability), and the intended lifecycle (`pending` → `dispatching` → `sent`/`failed`). The beneficiary is developers/operators who need honest operational visibility and safe retry. Background explains the modeling issue: current `EmailDeliveryCreated` incorrectly creates `sent` status before provider acceptance, and command failure can occur after events commit. The outcome is explicit, async, observable dispatch separated from the domain command boundary.

### 2. Scope Focus

**✅ Focused on one coherent outcome.**

The scope is tightly bounded: make the existing outbound club-message email dispatch async and honest. The iteration deliberately excludes:
- External job systems (Oban).
- Automatic retry/sweeping.
- Staff retry UI.
- Event renaming (MessageSent).
- Obliterating deprecated `opened` status.
- Member/staff copy redesign.
- Other CQRS/event-sourcing bloat identified in the design review.

The in-scope work is minimal:
- Change initial status from `sent` to `pending`.
- Add dispatch lifecycle.
- Remove synchronous provider call from `send_club_message/2`.
- Add supervised dispatcher with PubSub nudge.
- Add manual retry API.
- Adapt inbound acceptance.

Could it be smaller? Only marginally (see "Smallest Viable Iteration" above). The inbound acceptance adaptation is a consistency win, not scope creep. The plan is **already minimal while remaining useful**.

### 3. Acceptance Criteria, BDD Scenario Decision, and Business Decisions

**✅ Concrete, clear, complete, testable; iteration type and Gherkin rationale are explicit; no unresolved business decisions.**

**Acceptance criteria** cover:
- Happy path: `send_club_message/2` no longer calls provider, returns success, creates `pending` deliveries, dispatcher moves them to `sent`.
- Provider error: delivery marked `failed`, attempt count/error persisted.
- Partial failure: one recipient failure doesn't block others.
- Manual retry: succeeds without duplicate events.
- State changes: `pending` → `dispatching` → `sent`/`failed`, existing webhook statuses preserved.
- Replay safety: provider calls only in dispatcher/retry path, not during aggregate/projector replay.
- Observability: member-facing views hide infrastructure detail, staff/operator diagnostics show status/error.
- Inbound acceptance: uses same async dispatch path.
- Tests: message acceptance without provider call, dispatcher success/failure, partial failure, manual retry, inbound acceptance, replay safety.
- `dev check` passes.

These are **objectively testable** and cover happy path, provider failure, partial failure, replay safety, retry, member/staff presentation, and inbound acceptance.

**Iteration type**: Classified as "Technical/engineering" with clear rationale (no new user-observable business behaviour, internal CQRS/event-sourcing boundary improvement).

**Acceptance Scenarios / Feature Files**: Section present with explicit rationale: "This is an internal architectural slice with no new business rule or stakeholder-facing workflow. Existing acceptance scenarios ... should continue to pass. Coverage should be added or updated in ExUnit tests..." This is the correct decision and meets the plan requirement.

**Business decisions**: "Open Business Decisions: None known."

### 4. Implementation Plan and Technical Decisions

**✅ Clear, ordered, specific steps with named files/modules.**

The 14-step plan is sequential and concrete:
1. Inspect current paths: names `send_club_message/2`, `deliver_to_provider/1`, `email_delivery_request/3`, projectors, provider adapters.
2. Update `EmailDelivery` projection/schema for `pending` status, diagnostics, timestamps.
3. Add DB constraints/validation for expanded status vocabulary.
4. Introduce `Memba.Messaging.EmailDeliveryDispatcher` under supervision tree.
5. Dispatcher subscribes to `Memba.ReadModelChanges.topic()`, reacts to `EmailDeliveryCreated`.
6. Claiming logic: `pending` → `dispatching` before provider call.
7. Move request-building/provider-call logic into dispatcher/collaborator.
8. Provider success → `sent`, provider error → `failed` + diagnostics.
9. Remove synchronous provider call from `send_club_message/2`.
10. Add internal/manual retry API.
11. Adapt inbound acceptance to async dispatch.
12. Adjust member/staff presentation.
13. Add/update tests.
14. `dev check`.

Steps name modules (`Memba.Messaging.EmailDeliveryDispatcher`, `Memba.Messaging.Projectors.EmailDelivery`), integration points (`Memba.ReadModelChanges` PubSub topic), and data/state changes (status transitions, diagnostics fields).

**Open Technical Decisions**: "None known." The plan explicitly lists the design choices that are now decided (use `EmailDelivery`, use `pending`/`dispatching`/`sent`/`failed`, use OTP dispatcher + PubSub, manual retry only, no `MessageSent` rename).

### 5. Expected Capability and Validation

**✅ Clear stop condition and validation plan.**

**Expected capability** (from "New Capability" section): "Developers/operators can reason about outbound provider dispatch as an explicit, asynchronous lifecycle on each `EmailDelivery`. Provider outages or misconfiguration become observable failed delivery dispatches with retry diagnostics instead of misleading `send_club_message/2` failures after message events have already committed."

**What we can do after**: Observe dispatch lifecycle, retry failed deliveries manually, separate domain command acceptance from provider availability.

**Validation plan**: Covered above. Tests, `dev check`, manual dev inspection, manual provider failure simulation.

**Stop condition**: All acceptance criteria met + `dev check` passes.

---

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}