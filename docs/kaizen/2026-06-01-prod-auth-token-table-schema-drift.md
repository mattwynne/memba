# Problem: prod auth token table drift caused sign-in 500

Date: 2026-06-01

## Context

While configuring Resend and testing production sign-in on Fly.io, the `/auth` page loaded successfully but submitting the sign-in form returned an internal server error.

Relevant workflow steps:

- Resend support was added and deployed to Fly.io.
- Production data was intentionally cleaned because there was no valuable prod data yet.
- A sign-in smoke test was attempted against `https://memba.io/auth`.

## Expected standard

After a deploy runs the release migration command, the production database schema should match the application code's Ecto schemas. A smoke test should fail only for product behaviour, configuration, or provider errors, not because a supposedly migrated table has the wrong name.

## What happened

Fly logs showed the sign-in request failed with:

```text
POST /auth
Sent 500
** (Postgrex.Error) ERROR 42P01 (undefined_table) relation "auth_sign_in_tokens" does not exist
query: INSERT INTO "auth_sign_in_tokens" (...)
```

The application code expected:

```text
auth_sign_in_tokens
```

Production had:

```text
auth_magic_tokens
```

The migration record existed in `public.schema_migrations` for:

```text
20260531184305
```

The migration filename is:

```text
web/priv/repo/migrations/20260531184305_create_auth_magic_tokens.exs
```

but the migration module creates:

```elixir
create table(:auth_sign_in_tokens)
```

Because the migration version was already recorded as applied, the normal release migration command did not repair the table name.

Immediate workaround applied in production: manually renamed `auth_magic_tokens` to `auth_sign_in_tokens`, along with the sequence and indexes.

## Impact

This created a customer-facing 500 during the sign-in flow. It also consumed debugging time during a provider/deployment smoke test because the error appeared after several unrelated moving parts had changed: Resend secrets, Fly deploys, CD workflow recovery, and production data cleanup.

## What allowed it to happen

The delivery workflow did not have a guardrail that verifies the live production schema matches the current Ecto schema after migrations.

Specific weaknesses observed:

- A migration filename referenced the old domain name `auth_magic_tokens` while the migration body and code use `auth_sign_in_tokens`, making schema history harder to reason about.
- `schema_migrations` can say a migration ran even when the resulting schema shape does not match current code expectations.
- The production data cleanup step verified row counts, but not expected table names or schema shape.
- The release migration command only applies pending migrations; it does not detect drift in already-applied migrations.
- The sign-in smoke test was the first signal that the schema was wrong, so the abnormality appeared as a user-facing 500 instead of an operator-facing preflight failure.

## Observations

- The application booted and served public pages, so the deploy looked healthy until `/auth` attempted a write.
- The root error was clear once logs were inspected, but the workflow did not surface it before manual testing.
- The immediate repair was safe only because Matt confirmed there was no production data worth preserving.
- The problem is delivery-machinery related because the issue was not just a product bug: the workflow allowed production schema drift to survive migration, cleanup, deploy, and health checks.

## Why this matters

If this happens after real customer data exists, manually renaming or truncating tables becomes risky. Future deploys need a way to make schema drift impossible, obvious, or easy to recover from before a user-facing flow fails.

## Open questions

- How did production originally get `auth_magic_tokens` when the committed migration creates `auth_sign_in_tokens`?
- Was an earlier migration version deployed and later edited in place before production was reset?
- Should production cleanup/reset use a scripted release task instead of ad hoc SQL?
- Which smoke checks should run after deploy before we consider production healthy?

## Possible prevention ideas

- Add a schema-drift smoke check that verifies required production tables exist after migrations.
- Add or repair migrations rather than editing migration files after they may have run anywhere.
- Add a release task for safe non-customer-data environment reset that drops/recreates schemas from migrations.
- Include `/auth` sign-in token creation in post-deploy smoke testing, using a controlled test address.

## Resolution

Date: 2026-06-01

Root cause: The auth token migration was edited in place after its version had already been deployed. Production had version `20260531184305` recorded in `schema_migrations`, so the release migration command correctly skipped it even though the physical table still used the earlier `auth_magic_tokens` name. The release workflow had no post-migration schema-shape check, so the drift reached the sign-in flow.

Fix applied:

- `web/lib/memba/release.ex`: after release migrations, verify that the public database has the tables and columns required by the current Ecto schemas and projection bookkeeping. The release command now fails with an operator-facing schema-drift error instead of allowing a user-facing 500.
- `web/test/memba/release_test.exs`: added coverage for the release schema verification, including the specific old-auth-table drift case.
- `web/priv/repo/migrations/20260531184305_create_auth_sign_in_tokens.exs`: renamed the migration file to match the table it now creates while preserving the deployed migration version.

Validation:

- `./bin/dev check` — passed, 315 tests, 0 failures.

Remaining follow-up:

- Consider adding a production smoke command that runs `Memba.Release.verify_schema!()` explicitly after deploy and before manual sign-in smoke tests.
