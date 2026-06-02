# Problem: acceptance lifecycle calls removed `dev postgres` subcommand

Date: 2026-06-01

## Context

While fixing club-message email sender behaviour, I added an acceptance scenario assertion and tried to run the affected browser scenario:

```bash
cd acceptance-tests && npx cucumber-js features/member_message_deliverability.feature --name "Alice sends a club message"
```

I then retried through the project wrapper:

```bash
./bin/dev acceptance
```

## Expected standard

The acceptance workflow should start or verify its required local services through current project standard work. A contributor should be able to run `./bin/dev acceptance` and have the browser acceptance harness bring Postgres, database setup, assets, and Phoenix into a ready state, or fail with an actionable environment problem.

Because `bin/dev` no longer exposes a public `postgres` subcommand, acceptance lifecycle code should not depend on that removed interface.

## What happened

Both acceptance commands failed before any scenario ran. The Cucumber `BeforeAll` hook in `acceptance-tests/features/support/world.js` reported that Postgres readiness failed because the lifecycle tried to run a stale command:

```text
Postgres readiness failed: exited with code 1.
Command: /Users/matt/git/mattwynne/memba/bin/dev postgres
Recent output:
[Postgres readiness] error: `dev` requires a subcommand but 'postgres' is not one of them
[Postgres readiness]   [subcommands: up, down, ci, check, sandbox_check, sandbox-check, acceptance, iteration, fabro]
```

The call site is in `acceptance-tests/features/support/lifecycle.js`:

```javascript
await processRunner.run(buildDevCommand(currentConfig, "postgres"), {
  label: "Postgres readiness",
  timeoutMs: currentConfig.commandTimeoutMs,
  logBuffer
});
```

## Impact

This blocked running the changed acceptance scenario through the normal browser acceptance workflow. It forced fallback to lower-level unit and support tests for immediate validation, even though the feature file was updated.

Severity: workflow friction and quality risk. The product code could still be checked with `dev check`, but acceptance evidence is unavailable until the lifecycle and `bin/dev` command contract are brought back into alignment.

## What allowed it to happen

A previous dev-script simplification removed the `dev postgres` subcommand, but the acceptance lifecycle still had a direct dependency on that command string. There was no guardrail tying the accepted `bin/dev` subcommand list to the lifecycle's service-start contract, and `dev check` did not exercise the acceptance lifecycle.

The stale dependency surfaced only when running Cucumber acceptance tests, not when running the standard Elixir test suite.

## Observations

- `./bin/dev acceptance` delegates to the acceptance test suite, but the suite itself tries to call `bin/dev postgres` during `BeforeAll`.
- `bin/dev` now advertises these subcommands: `up`, `down`, `ci`, `check`, `sandbox_check`, `sandbox-check`, `acceptance`, `iteration`, and `fabro`.
- The failure happens before database setup, asset build, app startup, or scenario execution.
- The error message is clear once seen, but it appears late in the acceptance run rather than as a dev-script contract check.
- The affected product change was still validated with `cd web && mix test`, acceptance support tests, and `dev check`, but the browser scenario itself did not run.

## Why this matters

Acceptance tests are living documentation and the main guardrail for user-visible workflows. If their lifecycle depends on an untested, removed internal command, scenario changes can look blocked by product infrastructure rather than by product behaviour. Future agents may waste time debugging Postgres or Cucumber when the real issue is a stale workflow contract.

## Open questions

- Should the acceptance lifecycle start Postgres through a current public `bin/dev` command, through `devenv processes`, or through a smaller dedicated helper?
- Should `dev check` include a lightweight acceptance-lifecycle smoke test, or should `dev acceptance` have its own preflight that validates the lifecycle command contract before Cucumber starts?
- Was `dev postgres` intentionally removed as a public interface without updating all known callers, or was it meant to remain available as an internal helper?

## Possible prevention ideas

- Replace the stale `buildDevCommand(currentConfig, "postgres")` dependency with the current service-start standard.
- Add a regression test for `acceptance-tests/features/support/lifecycle.js` that fails if it references unsupported `bin/dev` subcommands.
- Add a `bin/dev acceptance` preflight that validates its service lifecycle commands against the actual `bin/dev` interface before launching Cucumber.
- Document which `bin/dev` subcommands are public workflow contracts versus private implementation details.

## Resolution

Date: 2026-06-01

Root cause: The acceptance lifecycle kept a hard-coded call to the removed `bin/dev postgres` subcommand. The current `bin/dev` service-start contract starts Postgres through `devenv processes`, but the lifecycle never moved to that contract and its unit tests only asserted high-level step labels, not the command surface.

Fix applied:

- `acceptance-tests/features/support/lifecycle.js`: replaced the stale `buildDevCommand(currentConfig, "postgres")` call with a Postgres readiness command that uses `devenv processes status`, `devenv processes up --no-strict-ports -d postgres`, and `devenv processes wait --timeout 120` on the selected acceptance Postgres port.
- `acceptance-tests/test/lifecycle.test.js`: added a regression check that Postgres readiness uses the `devenv processes` contract and does not call `bin/dev postgres`.

Validation:

- `cd acceptance-tests && node --test test/lifecycle.test.js` — passed, 6 tests.
- `cd acceptance-tests && npx cucumber-js features/member_message_deliverability.feature --name "Alice sends a club message"` — passed Postgres readiness, database setup, asset build, and Phoenix startup; the scenario then failed in product/support behaviour because the sign-in email assertion did not match the current link format.
- `./bin/dev check` — ran twice and failed both times with a repeatable PostgreSQL deadlock in `test/memba/membership/person_email_address_projection_test.exs:13`; the targeted test file passed with `cd web && mix test test/memba/membership/person_email_address_projection_test.exs`.

Remaining follow-up:

- Investigate the unrelated `dev check` deadlock in `Memba.Membership.PersonEmailAddressProjectionTest`.
- Investigate the unrelated acceptance scenario failure around magic-link email parsing/sign-in copy.
