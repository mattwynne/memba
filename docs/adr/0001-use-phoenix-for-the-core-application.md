# 1. Use Phoenix for the core application

Date: 2026-05-21

## Status

accepted

## Context

Memba needs a robust multi-tenant web application for club membership records, renewals, payments, roles, member-only content, directories, email workflows, and integrations such as WordPress login during transition. AT Protocol and mobile apps are possible future extensions, but they are not required for the first useful version.

## Decision

Use Elixir/Phoenix, Phoenix LiveView, and PostgreSQL for the core Memba application.

Keep the core domain independent from AT Protocol. If AT Protocol becomes necessary, add it later as an integration, likely via a separate TypeScript service.

## Consequences

Phoenix gives us a productive, reliable stack for database-backed workflows, admin screens, background jobs, and server-rendered interactivity. PostgreSQL remains the source of truth for tenant-scoped membership data.

AT Protocol integration may require additional TypeScript components later. Mobile apps will need API work when they become a priority.
