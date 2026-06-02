# 17. Treat release state as a first-class production artifact

Date: 2026-06-02

## Status

accepted

## Context

A production auth smoke test failed with a 500 because the application tried to insert into `auth_sign_in_tokens`, while the production database still had the earlier `auth_magic_tokens` table.

The migration version was recorded in `schema_migrations`, so the release migration command had no pending work to apply. Local tests did not catch the problem because local and test databases were rebuilt from the current migration files. Production had applied an older body for the same migration version.

This incident exposed a delivery-system defect: we treated committed code and green tests as sufficient evidence, while the live production schema state was only checked indirectly by a user-facing sign-in attempt.

## Decision

Treat production release state as a first-class artifact that must be verified explicitly.

Migration discipline:

- Once a migration may have run in any shared, staging, or production database, do not edit it in place.
- Make every later schema change with a new migration, even when the original migration name or body is awkward.
- If a migration filename, module name, or table name disagree, treat that as a defect signal and inspect migration history before deploy.

Release verification:

- After release migrations run, verify that the live database shape matches current application expectations.
- Keep schema verification in the release path, not only in local tests.
- Fail the deploy or release task with an operator-facing schema-drift error when required tables or columns are missing.

Production smoke testing:

- Smoke tests must exercise the changed production path, not only app boot or public page load.
- For auth/email changes, smoke-test token creation and provider handoff with a controlled address before declaring production healthy.
- Treat production data cleanup/reset as a release operation: script it, capture output, and verify schema/application invariants afterwards.

## Consequences

This makes production drift harder to miss. A recorded migration version is no longer mistaken for proof that the live schema matches the code.

Deploys may fail earlier and more noisily when production state is wrong. That is intentional: an operator-facing release failure is preferable to a customer-facing 500.

We accept a small amount of release-check maintenance. As new persistent Ecto schemas or manually-managed projection tables are added, the schema verification must continue to reflect the application's required production shape.

Local test rebuilds remain valuable, but they are not enough. Long-lived environments need their own verification because they have history.
