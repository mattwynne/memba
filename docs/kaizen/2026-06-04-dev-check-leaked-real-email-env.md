# Problem: dev check leaked real email provider configuration

Date: 2026-06-04

## Context

While switching local development email from Resend to a dedicated Postmark dev server, `.local/secrets.envrc` was updated to select real Postmark delivery for manual dev use:

- `MEMBA_EMAIL_PROVIDER=postmark`
- `MEMBA_POSTMARK_SERVER_TOKEN`
- `MEMBA_MESSAGING_FROM_ADDRESS=messages@mail-dev.memba.io`
- `MEMBA_AUTH_EMAIL_FROM_ADDRESS=auth@mail-dev.memba.io`
- `MEMBA_AUTH_EMAIL_MESSAGE_STREAM=outbound-authentication`

After the Postmark/DNS changes, we ran the standard project quality gate:

```sh
./bin/dev check
```

## Expected standard

`./bin/dev up` should load local secrets for production-like manual development.

`./bin/dev check` should run automated tests against local/fake email adapters unless a test explicitly opts into real provider behaviour. Automated checks should not send real email or depend on real provider domains, tokens, rate limits, or webhook state.

## What happened

The first `./bin/dev check` failed because Postgres had too many connections. After `./bin/dev down`, the process manager was gone but an orphaned Postgres process was still running and stuck in `stopping`. We stopped it directly:

```sh
pg_ctl -D .devenv/state/postgres stop -m fast
```

After that, `./bin/dev check` reached the tests but ExUnit leaked real provider configuration from `.local/secrets.envrc`. Tests that expected fake/local delivery attempted real provider calls instead. Evidence included failures with real provider responses:

- Resend `403` domain-not-verified errors for `mail.memba.io`;
- Resend `429` rate-limit errors;
- fake-provider assertions such as `Fake.deliveries() == []` because the fake adapter was not being used.

A later fix made `precommit` and acceptance run under a helper that unsets real provider environment variables. `./bin/dev check --quick` then passed with 503 tests and 0 failures. Full `./bin/dev check` still hit browser projection timing failures, which appear separate from the email environment leakage.

## Impact

This created avoidable debugging noise and risked accidental real provider calls from routine local checks. It also blurred the signal: failures initially looked like provider/domain problems even though the quality gate should not have been using a provider at all.

The orphaned Postgres process also made recovery less obvious: `dev down` reported no process manager running, but Postgres still held sockets/sessions and blocked clean reruns.

## What allowed it to happen

Two workflow guardrails were weak:

1. `dev check` reused the shell environment that is useful for `dev up`, without explicitly clearing real email provider variables before running automated tests.
2. The dev process lifecycle could leave Postgres orphaned outside the process manager, so `dev down` did not fully restore a clean baseline.

## Observations

- `.local/secrets.envrc` is serving two different purposes: manual production-like dev and ambient environment for quality gates.
- The project already had intent in `docs/postmark-email.md`: automated tests should use local/fake delivery unless explicitly doing a manual smoke test.
- The command boundary between `dev up` and `dev check` needs to enforce that intent, not rely on the caller remembering which env vars are present.
- The direct `dev up`/`dev restart` fast path had also bypassed the new Postmark webhook sync until corrected.
- A failed Cucumber run left a Phoenix test server alive with many idle `memba_test` database sessions, which then blocked the next acceptance setup from dropping the test database.

## Why this matters

Routine quality gates should be deterministic, cheap, and safe. If they inherit real provider configuration, they can fail for external reasons, hit rate limits, send unwanted email, or hide product regressions behind infrastructure noise.

Similarly, if `dev down` cannot reliably clean up managed services, every retry becomes more expensive and less trustworthy.

## Open questions

- Should `dev check` always force a known test-email profile, even if run from inside an already-loaded devenv shell?
- Should `dev down` detect and stop orphaned Postgres/Phoenix/Cucumber processes for this project?
- Should acceptance lifecycle cleanup include a stronger trap/kill path for Phoenix test servers after failures?
- Should there be a preflight warning when `mix test` sees real provider env outside an explicit smoke-test command?

## Possible prevention ideas

- Keep `local_test_email_env` or an equivalent env scrubber as the standard wrapper for automated tests.
- Add a `dev doctor` or `dev reset-processes` command that reports orphaned Postgres, Phoenix, Cucumber, and process-compose state.
- Add a test or shellcheck-style assertion that `dev check` unsets real email provider variables.
- Consider making app test config fail fast if `MEMBA_EMAIL_PROVIDER` is set during ordinary `MIX_ENV=test` runs without an explicit opt-in.
