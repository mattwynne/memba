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

## Deferred follow-up: Postgres lifecycle ownership

Matt requested that a later agent take on a comprehensive overhaul rather than an ad hoc patch. Investigate and redesign the ownership contract across `bin/dev`, `bin/mix`, and `acceptance-tests/features/support/lifecycle.js`: nested phases must not independently stop, start, or clean up a service owned by their parent; separate check/worktree isolation also needs an explicit contract. This follow-up should establish the target design and regression coverage before changing lifecycle behaviour.

## Resolution

Date: 2026-09-20

Root cause: Postgres ownership was implicit and conflicting. `bin/dev` treated the existence of a process status record as readiness, so it could pass a stopped or failed service downstream. Browser acceptance independently started and (outside a devenv shell) tore down the service, while its nested `bin/mix` commands could run `devenv processes down` and restart it. A failed nested readiness check could therefore reset the parent command's shared process manager and produce the observed stale `postmaster.pid`/restart loop.

Fix applied:

- `bin/dev`: explicitly exports `MEMBA_POSTGRES_OWNER=dev`, waits for a ready/running phase rather than merely a status record, and starts Postgres before direct `dev acceptance` runs.
- `bin/mix`: is now a checkout-local Mix resolver only; it never starts, resets, or tears down the parent service.
- `acceptance-tests/features/support/lifecycle.js`: makes the owner explicit. A `dev` parent supplies the ready service and browser acceptance only consumes it; a standalone lifecycle owns startup and optional teardown, passing that ownership to every nested Mix/Phoenix command. Readiness now checks the managed process phase rather than accepting any status record.
- `acceptance-tests/test/lifecycle.test.js`: covers parent-owned and standalone ownership paths and prevents `bin/mix` from regaining process-manager commands.

Validation:

- `bash -n bin/dev bin/mix` — passed.
- `cd acceptance-tests && node --test test/lifecycle.test.js` — passed, 11 tests.
- `MEMBA_DEV_NGROK=0 ./bin/dev check` — passed with the staged executable fix: 1,529 ExUnit tests and 189 browser scenarios / 1,415 steps passed.
- A repeat after committing was terminated by the 1,200-second command limit while browser acceptance was still running; it reported no assertion failure before termination. This is not a passing final-commit attestation.

Expected versus observed: `dev check` was expected to serialize work for its selected Postgres port, start or reuse a ready service once, and leave acceptance/Mix unable to reset it. The staged executable gate passed end-to-end with that parent-owned lifecycle. This validates the mechanism once; it does not yet demonstrate long-term recurrence prevention.

Follow-up resolution — exact-commit publication attestation:

Root-cause evidence: all three Fabro paths that update `main` constructed or rebased the candidate after the graph's earlier `dev_check` node. `iteration-implementation/scripts/publish_to_main.sh` and `iteration-review/scripts/publish_polish_to_main.sh` then pushed that un-attested candidate directly; `iteration-review/scripts/finalize_iteration_status.sh` and `plan-validation/scripts/publish_ready.sh` had the same final `pull --rebase`/push gap. Thus even a prior successful gate was neither evidence for the final commit object nor a publish precondition.

Fix applied:

- `.fabro/workflows/scripts/attest_dev_check.sh` runs the full `./bin/dev check` in the clean, rebased publish worktree, rejects a changed or dirty candidate afterward, and records `Validated-Commit: <SHA>` plus the successful command in `refs/notes/fabro-dev-check`.
- Every Fabro path that pushes `main` now invokes that helper after its final rebase and pushes the attestation ref before pushing `main`: implementation delivery, review polish, review finalization, and plan validation.
- Publication-fixture tests now prove that each implementation/review/finalization commit was the SHA on which `./bin/dev check` ran and has its matching recorded note. The plan-validation workflow contract test prevents its attestation call or note publication from being removed.

Validation:

- `bash .fabro/workflows/iteration-implementation/scripts/test_publish_to_main.sh` — passed.
- `bash .fabro/workflows/iteration-review/scripts/test_publish_polish_to_main.sh` — passed.
- `bash .fabro/workflows/iteration-review/scripts/test_finalize_iteration_status.sh` — passed.
- `bash -n` over the changed Fabro shell scripts — passed.
- `./bin/dev check` — see this change's delivery validation.

Limitations:

- This is a guard on the Fabro delivery paths; a human or unrelated automation with direct permission to push `main` can still bypass it. Branch protection or server-side policy would be needed to make the requirement repository-wide.
- A Git note is durable only when clients fetch `refs/notes/fabro-dev-check`; the delivery scripts push it before `main`, but ordinary Git fetches do not necessarily fetch notes automatically.
- Review the next representative `dev check`/worktree run for a clean start, handoff, and teardown boundary.

### Additional observation: 2026-09-20 — direct pushes remain unenforceable on GitHub.com

The new Fabro attestation closes the known workflow paths, but it does not stop any actor with direct `main` push permission from bypassing it. GitHub.com cannot use a custom pre-receive hook to inspect the local Git note during a push. A repository-wide control therefore requires a GitHub branch ruleset that requires pull requests and a successful CI status check for the exact PR head SHA; Fabro would need to publish through that PR path rather than push `main` directly.

This is a delivery-policy gap, not a defect in the local attestation helper. The remaining decision is whether the added GitHub Actions/CI cost and PR workflow are acceptable in exchange for making the gate non-bypassable.
