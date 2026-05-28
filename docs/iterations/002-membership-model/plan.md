# Membership model

Date: 2026-05-28
Status: ready

## Goal

Extend the Membership context with Person and Membership aggregates and a
public Membership query API for resolving active club members. After this
iteration, the Background of both shared deliverability feature files
passes.

## Background / Context

Iteration 001 stood up the Commanded/EventStore + projections + Cucumber
toolchain with a single `Club` aggregate. This iteration completes the
minimal Membership model that Messaging will depend on in iteration 003.

Relevant ADRs:

- ADR 0007: separate Membership and Messaging contexts. Messaging must call
  Membership's public query API, not its Ecto schemas.
- ADR 0011: caller-supplied UUID identities.

Membership in this slice is intentionally minimal: people become members at
creation and stay active for the rest of the iteration's purposes. Lapsing,
revocation, households, renewals, and privacy are out of scope.

## Scope

### In scope

- `Person` aggregate: `CreatePerson` with name and email; club-independent
  identity.
- `Membership` aggregate: `AddMember` (or equivalent) attaching an existing
  person to an existing club; active from creation.
- Projections for Person and Membership.
- Public Membership query API including
  `list_active_members_of_club/1` returning enough identity to drive recipient
  resolution (id, name, email).
- Cucumber step definitions for all Background lines in
  `member_message_deliverability.feature` and
  `operator_email_deliverability.feature`:
  - "<Club> is a club"
  - "<People> are people" / "<Person> is a person"
  - "<People> are members of <Club>" / "<Person> is a member of <Club>"
- ExUnit coverage for Person and Membership aggregate rules and projector
  behaviour.

### Out of scope

- Anything Messaging.
- Lapsed/revoked membership.
- Household or family modelling.

## Acceptance Criteria

- `Memba.Membership.list_active_members_of_club/1` returns the active
  members of the given club and excludes members of other clubs.
- A person created independently can be added as a member of a club via
  domain commands.
- Background steps for both shared feature files pass under Elixir Cucumber.
- ExUnit covers aggregate decisions and projector behaviour.
- `devenv shell mix precommit` passes.

## Implementation Plan

1. Add `Person` aggregate, `CreatePerson` command, `PersonCreated` event,
   and Person projector + query.
2. Add `Membership` aggregate, `AddMember` command, `MemberAdded` event,
   and Membership projector.
3. Implement `list_active_members_of_club/1` and supporting queries on the
   Membership context boundary.
4. Add Cucumber step definitions for all Background lines in both feature
   files, using the public Membership API.
5. Run `devenv shell mix precommit` and fix any issues.

## Validation Plan

- Cucumber Background of both feature files passes.
- ExUnit covers aggregate rules, projector behaviour, and the query API.
- `devenv shell mix precommit` passes.

## Risks / Follow-ups

- The minimal membership model will need to evolve soon (lapsed/active,
  households, renewals, privacy). That work belongs to a later iteration.
- Iteration 003 implements Messaging on top of this API.
