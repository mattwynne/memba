# Route membership writes through the Club aggregate

Date: 2026-09-11
Status: eval-fixture

## Goal

Club administrators can add and remove members while the Club aggregate protects the invariant that every populated club has at least one administrator.

## Background / Context

Membership commands currently route to Membership streams. This iteration moves membership activation and removal into Club state so the club-wide administrator invariant can be checked at one consistency boundary.

## Scope

### In scope

- Route `AddMember` and `RemoveMember` commands to the Club aggregate by `club_id`.
- Store active membership and role state in the Club aggregate.
- Reject duplicate active memberships from rehydrated Club state.
- Remove the membership projection preflight used before dispatching `AddMember`.
- De-register the membership-ID command-router identity for membership writes.
- Preserve caller-generated `membership_id` values on membership events.

### Out of scope

- Changing message aggregates or delivery behaviour.
- Changing club creation.
- Rebuilding membership read models.

## Iteration Type

Behaviour-facing. This changes the consistency rule used when club administrators add and remove members.

## Acceptance Scenarios / Feature Files

Use the existing administrator and membership scenarios in `acceptance-tests/features/club_membership.feature`. No feature-file edits are needed because those scenarios already express the observable rules.

## Designs

No design needed. The iteration changes command routing and invariant enforcement without changing a visible surface.

## Acceptance Criteria

- `AddMember` and `RemoveMember` dispatch by `club_id` to the Club aggregate.
- A populated club cannot remove its last administrator.
- Duplicate active membership for the same `{club_id, person_id}` is rejected from rehydrated Club state without querying a projection before dispatch.
- Membership events retain a caller-generated `membership_id`.
- Existing membership acceptance scenarios remain green.
- `dev check` passes.

## Open Business Decisions

None.

## Implementation Plan

1. Add active membership and administrator role state to the Club aggregate.
2. Route `AddMember` and `RemoveMember` commands by `club_id`.
3. Remove the membership-ID write route from the Membership router.
4. Move duplicate active-membership validation from the projection preflight into Club command handling.
5. Add aggregate and application tests for duplicate membership and last-administrator protection.
6. Run `dev check`.

## Open Technical Decisions

None. Club is the consistency boundary for membership activation and removal.

## New Capability

The write model enforces club-wide membership and administrator invariants from rehydrated Club state.

## Validation Plan

- Run focused Club aggregate and membership application tests.
- Run the existing shared membership acceptance scenarios.
- Run `dev check`.

## Risks / Follow-ups

The routing change is intentionally limited to membership activation and removal.
