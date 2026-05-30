# Delivery statuses, member receipts, and operator views

Date: 2026-05-28
Status: merged

## Goal

Complete the user-facing capability "member message deliverability" by
implementing the per-recipient delivery status state machine, the simple
member-facing receipt mapping, and the detailed operator deliverability view
with reason preservation. After this iteration, all scenarios in both
shared feature files pass.

## Background / Context

Iteration 003 left messages and per-recipient deliveries in `sent` state and
addressed the recipient fan-out. This slice adds the rest of the lifecycle.

Relevant ADRs:

- ADR 0004: one Message aggregate per message owns its delivery state.
- ADR 0006: simplified member-facing delivery status mapping.
- ADR 0012: track only whether a delivery was opened at least once, not how
  many times.

## Scope

### In scope

- Delivery status state machine inside the Message aggregate, covering
  per-recipient statuses: sent, delivered, delayed, bounced, spam complaint,
  opened.
- Invalid transitions rejected; repeated equivalent status reports
  idempotent.
- `Opened` semantics per ADR 0012: idempotent boolean per recipient
  delivery; no open counts, last-opened time, or device diagnostics.
- Member-facing receipt projection and query implementing the ADR 0006
  mapping: sent / delivered / delivery problem / opened.
- Operator deliverability projection and query: detailed per-member status
  including reason/detail text for delayed, bounced, and spam complaint.
- Cucumber step definitions for all remaining scenarios in
  `member_message_deliverability.feature` and
  `operator_email_deliverability.feature`.
- Final cleanup of any CRUD spike remnants surfaced by the previous slices.
- ExUnit coverage for status transitions, idempotency, and projector
  behaviour where Cucumber does not provide enough diagnostic depth.

### Out of scope

- Real Postmark integration, webhooks, tracking pixel HTTP endpoint.
- Phoenix UI.
- Read receipts beyond the boolean opened state.
- Repeated-open analytics or device/client breakdowns.

## Acceptance Criteria

- All scenarios in `member_message_deliverability.feature` pass under
  Elixir Cucumber.
- All scenarios in `operator_email_deliverability.feature` pass under
  Elixir Cucumber, with reason text preserved for delayed, bounced, and
  spam complaint statuses.
- Invalid status transitions are rejected by the Message aggregate.
- Repeated equivalent status reports (including repeated opens) are
  idempotent.
- The CRUD spike is fully removed where any remnants conflict with the
  event-sourced model.
- `devenv shell mix precommit` passes.

## Implementation Plan

1. Extend the Message aggregate with commands and events for delivered,
   delayed, bounced, spam complaint, and opened reports, plus the
   transition rules and idempotency checks.
2. Add the member-facing receipt projection and query applying the ADR 0006
   mapping.
3. Add the operator deliverability projection and query, preserving reason
   text on delayed, bounced, and spam complaint events.
4. Add Cucumber step definitions for the remaining member receipt scenarios
   and all operator scenarios.
5. Sweep the codebase for any remaining CRUD spike artefacts and remove
   them where they conflict with the event-sourced design.
6. Run `devenv shell mix precommit` and fix any issues.

## Validation Plan

- Both shared feature files pass end to end under Elixir Cucumber.
- ExUnit covers status state machine rules, idempotency, and projector
  behaviour for both member receipts and operator views.
- `devenv shell mix precommit` passes.

## Risks / Follow-ups

- Live provider integration (likely Postmark) is the next iteration: real
  sending, webhook ingestion, tracking pixel endpoint, and a manual
  cross-inbox demo.
- The operator view will evolve as we learn what operators actually need;
  the projection shape here is intentionally minimal.
