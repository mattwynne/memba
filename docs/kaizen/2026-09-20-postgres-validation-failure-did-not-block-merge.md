# Problem: Postgres validation failure did not block merge

Date: 2026-09-20

## Context

After rescuing the Iteration 063 review repair and applying its review-workflow kaizen change, the final required quality gate was run with `bin/dev check` on commit `3939249de`.

The project standard in `AGENTS.md` requires `dev check` after code or executable-workflow changes, and says it may be reported as passing only on the exact committed/pushed state (or a clean worktree with the same staged diff). The rescued work was merged and pushed before that gate completed successfully.

## Expected standard

A merge or push of work requiring `dev check` must wait for a successful full check on the exact state. If the check is blocked by local infrastructure, the work must remain unmerged and the blocker must be made explicit until it is resolved or an authorised alternative validation path is chosen.

## What happened

The first `bin/dev check` ran 1,529 ExUnit tests successfully, but browser acceptance could not start. Its lifecycle attempted to drop and recreate the test database; PostgreSQL reported an existing `postmaster.pid` and then failed to become ready.

A second `bin/dev check` did not reach tests: devenv reported that its managed `postgres` process had given up after five restarts.

Despite the incomplete quality gate, commits `28e8326ca` (`test: strengthen web membership command boundary`) and `3939249de` (`kaizen: prevent review repair detached gate stalls`) were merged to and visible on `origin/main`.

## Impact

The main branch received code and executable workflow changes without the required complete acceptance validation. The unavailable Postgres service also prevented a reliable conclusion about whether the change was safe, forcing manual follow-up and reducing trust in the release gate.

## What allowed it to happen

The delivery process treated a partial quality-gate result and an infrastructure failure as enough to proceed with merge/push. There was no effective final handoff guard requiring a recorded successful `dev check` for the exact commit before publishing.

The Postgres failure itself was not diagnosed before publishing. The existing quality-gate locking work in `docs/kaizen/2026-06-04-dev-check-concurrent-runs-race.md` serializes shared validation commands, but this observation shows that managed-process health and final-publish eligibility still need investigation.

## Observations

- The failing acceptance lifecycle reported a pre-existing Postgres lock file, then a database-system shutdown while waiting for the service.
- The next run reported `Timed out waiting for managed process(es): postgres (gave_up)` with restart count 5.
- The observed failure is delivery machinery, not evidence of an Iteration 063 product defect.
- The exact causal relationship between concurrent processes, stale state, devenv process supervision, and the Postgres failure remains unknown.

## Why this matters

A quality gate that can be bypassed after an infrastructure failure cannot provide the final control it is meant to provide. Repeating this pattern risks publishing unvalidated regressions and encourages agents to interpret partial test success as sufficient.

## Open questions

- Why did managed Postgres fail to start and restart in this checkout?
- Was another `dev check`, acceptance lifecycle, or local service using the same Postgres state at the time?
- Which merge/publish path allowed the commits to reach `origin/main` without a recorded successful full check?

## Possible prevention ideas

- Require an explicit successful exact-commit `dev check` attestation before the delivery workflow can merge or push.
- Make `bin/dev check` report managed Postgres ownership, lock-holder/process details, and a safe recovery action when startup fails.
- Ensure agents treat infrastructure-blocked validation as a hard publish stop rather than a partial pass.
