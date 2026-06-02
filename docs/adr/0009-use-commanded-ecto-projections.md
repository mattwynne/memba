# 9. Use Commanded Ecto Projections

Date: 2026-05-26

## Status

accepted

## Context

Memba needs read models for event-sourced workflows. The first message deliverability slice needs projections for clubs, people, memberships, messages, email deliveries, member-facing email delivery queries, and Memba staff email delivery queries.

We could write custom Commanded event handlers that manually update Ecto tables. However, projections need idempotency, position tracking, and predictable replay behaviour.

## Decision

Use `commanded_ecto_projections` for Ecto-backed read models.

Projection modules should use the standard Commanded Ecto projection machinery to update Ecto schemas from domain events. Query modules may then expose public application queries over those projection tables.

## Consequences

This follows the normal Commanded/Ecto approach and avoids building custom projection plumbing too early.

Projection position tracking and replay behaviour are handled by a library designed for this purpose.

The project gains another dependency and contributors must learn its conventions, but that is preferable to hand-rolled projection infrastructure.
