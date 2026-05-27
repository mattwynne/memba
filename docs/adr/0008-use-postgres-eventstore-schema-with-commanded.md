# 8. Use PostgreSQL EventStore schema with Commanded

Date: 2026-05-26

## Status

accepted

## Context

Memba uses Commanded for CQRS/event-sourced domain workflows. The first message deliverability slice needs persistent event storage for development and test.

We considered:

1. Separate PostgreSQL databases for the EventStore and Ecto projections.
2. One PostgreSQL database per environment, with EventStore tables in their own schema and normal projections in the default application schema.
3. One database/schema for everything.
4. Commanded's in-memory adapter for tests.

The goal is to keep the setup simple while staying close to normal Commanded/EventStore practice.

## Decision

Use `commanded_eventstore_adapter` with the `eventstore` package.

Use the same PostgreSQL database as the Phoenix/Ecto app for each environment, but keep EventStore tables in a dedicated PostgreSQL schema, such as `event_store`. Normal Ecto projections/read models stay in the application schema.

Use the persistent EventStore adapter in test as well as development. Tests should reset/clean EventStore state rather than switching to an in-memory adapter.

## Consequences

This keeps operations simple: one database per environment, while still separating event-store tables from projection/read-model tables.

It follows the normal Commanded/EventStore shape closely enough that development and test exercise the real persistence path.

The setup needs explicit migration/setup/reset tasks for both Ecto projections and the EventStore schema. Test cleanup must clear event streams and projections between tests.
