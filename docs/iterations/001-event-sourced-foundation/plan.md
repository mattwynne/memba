# Event-sourced foundation (walking skeleton)

Date: 2026-05-28
Status: merged

## Goal

Stand up the Commanded/EventStore + `commanded_ecto_projections` + Elixir
Cucumber toolchain by round-tripping a single trivial aggregate end to end.
This iteration proves the architecture works so subsequent iterations can
focus on domain modelling rather than infrastructure.

The user-facing capability "member message deliverability" is delivered
across iterations 001–004; this iteration is the foundation slice.

## Background / Context

A previous attempt at this domain produced a plain Ecto CRUD spike. We are
replacing that with the event-sourced architecture chosen in ADRs 0002, 0007,
0008, 0009, 0010, and 0011.

Relevant ADRs for this slice:

- ADR 0002: Commanded and event sourcing by default.
- ADR 0007: separate Membership and Messaging Commanded contexts.
- ADR 0008: same PostgreSQL database with a dedicated EventStore schema.
- ADR 0009: `commanded_ecto_projections` for read models.
- ADR 0010: shared feature files with Elixir Cucumber.
- ADR 0011: caller-generated UUID aggregate identities.

The shared feature files at
`acceptance-tests/features/member_message_deliverability.feature` and
`acceptance-tests/features/operator_email_deliverability.feature` already
exist. This slice only needs to make the simplest possible step pass through
the full stack; later iterations make the remaining scenarios pass.

## Scope

### In scope

- Add dependencies and configuration:
  - `commanded`, `commanded_eventstore_adapter`, `eventstore`
  - `commanded_ecto_projections`
  - `{:cucumber, github: "huddlz-hq/cucumber"}`
- Configure EventStore in the same DB as the Phoenix/Ecto app, in a dedicated
  schema (e.g. `event_store`). Projections/read models stay in the
  application schema.
- Dev and test setup/reset so EventStore and projection tables are created
  and cleaned correctly.
- A single Membership Commanded app and router (`Memba.Membership.App`,
  `Memba.Membership.Router`).
- A single Club aggregate with caller-supplied UUID identity (ADR 0011).
- A `CreateClub` command and `ClubCreated` event.
- A Club projection and a public query (`Memba.Membership.get_club/1` or
  equivalent) sufficient to assert the aggregate round-tripped.
- Elixir Cucumber wired to read `acceptance-tests/features/**/*.feature` and
  execute Elixir step definitions from the Phoenix app test suite.
- Step definition for the existing Background line
  `Given Kootenay Mountaineering Club is a club` that drives a real
  `CreateClub` command.
- Removal of any prior CRUD spike code that conflicts with this skeleton.

### Out of scope

- Person, Membership, Messaging aggregates.
- Any delivery, status, receipt, or operator-view modelling.
- Making the rest of the shared feature scenarios pass.
- Phoenix UI, real provider integration, webhooks, tracking pixels.

## Acceptance Criteria

- `mix deps.get` resolves the new dependencies and the app boots in dev and
  test.
- The EventStore is initialised in its dedicated schema; running tests resets
  it cleanly.
- Sending `CreateClub` causes a Club to be queryable through the public
  Membership query API.
- Cucumber executes from the Phoenix test suite against the shared feature
  files and the chosen Background step passes.
- No CRUD-spike Membership context, schema, migration, or test remains where
  it conflicts with the event-sourced design.
- `devenv shell mix precommit` passes.

## Implementation Plan

1. Add the dependencies above with compatible versions; lock them in
   `mix.lock`.
2. Configure EventStore (dedicated schema) and `commanded_ecto_projections`
   in `config/*.exs`.
3. Add `mix` aliases / test helpers so EventStore + projection tables are
   created and reset in dev and test.
4. Add `Memba.Membership.App` and `Memba.Membership.Router`.
5. Add the `Club` aggregate, `CreateClub` command, and `ClubCreated` event,
   with caller-supplied UUID identity.
6. Add the Club projector and a public `Memba.Membership.get_club/1`
   read-side function.
7. Add Cucumber configuration that reads `acceptance-tests/features/**/*.feature`
   and a single step definition for the chosen Background step.
8. Remove conflicting CRUD spike code.
9. Run `devenv shell mix precommit` and fix any issues.

## Validation Plan

- ExUnit tests cover the Club aggregate, `ClubCreated` projector, and a
  minimal EventStore smoke test.
- Cucumber runs from the Phoenix test suite and the chosen Background step
  passes against the live event-sourced stack.
- `devenv shell mix precommit` passes.

## Risks / Follow-ups

- EventStore + projections setup may surface package-version or migration
  lifecycle issues. Resolving them here is the whole point of this slice.
- Iteration 002 adds Person and Membership aggregates and completes the
  Background of both shared feature files.
