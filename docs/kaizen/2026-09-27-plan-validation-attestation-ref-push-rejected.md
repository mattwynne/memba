# Problem: Plan validation could not publish after the shared attestation ref moved

Date: 2026-09-27

## Context

Matt approved `bin/dev fabro deliver docs/iterations/066-request-group-access/plan.md`. The ready plan was pushed on `main` at `8eaf741ec`; Fabro plan-validation run `01M3HP2AGED2JDXBBR90V1CPBW` reviewed it and selected `validated`. This was the validation stage of delivery, before implementation.

## Expected standard

A passing review and successful full `dev check` on the publish candidate should let `.fabro/workflows/plan-validation/scripts/publish_ready.sh` publish the validated plan, or fail with a precise, safe recovery route. The attestation gate introduced in [the Postgres validation note](2026-09-20-postgres-validation-failure-did-not-block-merge.md) should not turn unrelated attestations into competing updates that block delivery.

## What happened

`publish_ready` ran `./bin/dev check` and recorded a successful attestation for candidate `aecd0cbb3a711b87380256c68bef9a6cb7ba0dc8`, then `git push origin refs/notes/fabro-dev-check` was rejected with `(fetch first)`: `the remote contains work that you do not have locally`. The workflow terminated with `goal gate unsatisfied for node publish_ready and no retry target`. The rejected ref was **the Git notes attestation ref, not `main`**; the subsequent `git push origin HEAD:main` was never reached. The plan and index still say `ready`, and local `main` was clean and equal to `origin/main` after the run. The CLI summary only showed the trailing generic Git push hint, which initially made it look like a `main` non-fast-forward.

Run: [01M3HP2AGED2JDXBBR90V1CPBW](https://fabro.home.wynne.family/runs/01M3HP2AGED2JDXBBR90V1CPBW). Evidence: `fabro logs 01M3HP2AGED2JDXBBR90V1CPBW --no-upgrade-check`, failed `publish_ready` event at 2026-09-27T15:08:51Z.

## Impact

Iteration 066 did not begin implementation despite passing plan review and full validation of the candidate. The run spent about nine minutes and ended without a validated plan on `main`. Retrying delivery without understanding the shared ref could repeat the failure.

## What allowed it to happen

Observed mechanism: `.fabro/workflows/scripts/attest_dev_check.sh` adds a note to the locally available `refs/notes/fabro-dev-check`. Three publication scripts push that single shared ref directly (plan validation, implementation, and code-review healing). The earlier attestation note described four lifecycle paths, but this checkout has three actual raw notes pushes; review finalization is not a separate script here. A clone that has not incorporated the latest remote notes tip cannot fast-forward that ref, even if its note concerns a different commit. The plan-validation publish script has no fetch/merge/retry for the notes ref, and the tests check that a note is present and that push is invoked, but do not model a remote notes ref advancing independently. Whether another run moved the ref during this particular run, or the sandbox clone began without the current notes ref, remains unverified; both expose the same missing synchronization boundary.

## Observations

- The candidate's full `dev check` passed before the rejected notes push; no application-test failure caused this stop.
- The failure happened before the validated status could be published to `main`.
- The prior [attestation improvement](2026-09-20-postgres-validation-failure-did-not-block-merge.md) protects final publish candidates from unchecked changes, but introduces a single mutable shared notes ref at every publication boundary.
- The CLI's tail-only error omitted the failed ref and required run-log inspection to distinguish this from a `main` conflict.

## Why this matters

A shared attestation ref creates unnecessary contention among otherwise independent publishes. A passing delivery can stop after expensive checks, and the terse status can send recovery toward the wrong branch.

## Open questions

- Was the remote notes ref already ahead at clone creation, or did it advance while this run validated? Compare the run's local notes ref and remote ref history if recovery needs exact timing.
- Which attestation publication contract best keeps notes for different commits without losing evidence, and ensures `main` never advances before its attestation is remotely visible?
- Should the top-level failure summary include the rejected ref and candidate SHA?

## Possible prevention ideas

- Synchronize/merge the notes ref before publishing and bound retries for concurrent advances; test with an independently advanced bare remote notes ref across the actual publication paths.
- Alternatively use per-candidate immutable attestation refs or another concurrency-safe evidence store, with an explicit gate that the candidate has been attested before publishing `main`.
- Surface the exact failed ref in the command summary so a notes rejection is not mistaken for a `main` rejection.

## Resolution options

Date: 2026-09-27

Root cause: the shared Git notes ref is pushed as though a sandbox's local copy were current; the failure log proves the remote tip was ahead, but not when it advanced. Tests do not cover that concurrency/staleness case.

Options:

1. Keep Git notes, fetch and merge remote notes into the local ref before pushing, with a bounded race retry and conflict-safe behavior. This preserves the existing attestation format and consumers but adds shared-ref synchronization to all three publishers.
2. Use per-candidate immutable attestation refs with a verified lookup rule. This avoids a shared update but changes the evidence contract and needs broader migration and checks.
3. Contain only: diagnose and manually recover this run, without preventing recurrence. This restores delivery sooner but leaves the same late failure for another run.

Recommendation: option 1 if current notes consumers must remain stable; prove stale-clone and concurrent-writer cases in tests before changing publication. Do not force-push or remove the remote notes history.

Validation plan: reproduce the rejection with a test bare remote whose notes ref advances after clone; verify the chosen publisher merges without losing either attestation, rechecks candidate identity, and publishes `main` only after remote evidence is visible. Run relevant workflow tests and `dev check` on the completed code change. An actual delivery run is still needed to confirm operational effectiveness.

Status at observation: awaiting decision on the attestation publication contract; no workflow fix or run retry applied.

## Resolution

Date: 2026-09-27

Matt approved the deterministic shared-helper approach after clarifying that Git notes hold only exact-commit `dev check` evidence, not plan status. This correction covers the three actual notes-publishing scripts in this checkout; earlier discussion described four lifecycle paths based on the prior attestation note.

Root cause: the shared notes ref was published without incorporating remote notes updates. An unrelated attestation could make the push non-fast-forward; the workflow reported a failure after the full check had passed.

Fix applied:

- `.fabro/workflows/scripts/publish_dev_check_attestation.sh`: verify the candidate matches `HEAD` and its note, fetch and merge the remote notes ref without choosing between conflicting proofs, and retry a rejected push up to four times. Fail closed without pushing `main` when evidence cannot be preserved. Never force-push the shared ref.
- The plan-validation, implementation, and code-review publication scripts call that helper after attesting and before pushing `main`.
- `.fabro/workflows/scripts/test_publish_dev_check_attestation.sh`: exercise sandboxes with initially absent/stale notes, independent attestations, a racing writer between fetch and push, and a mismatched candidate. Existing publisher fixtures and plan-validation contract check the integration.

Validation: the deterministic helper fixture passed stale and racing writer cases; implementation and code-review publisher fixtures passed. A full `bin/dev check` completed with 1,572 ExUnit tests and five browser journeys passing, but unrelated acceptance-test changes appeared unstaged in the shared checkout during that run, so it is not an exact-state attestation. A clean committed-state `dev check` is still required. The fixture validates the concurrency mechanism; prevention in the remote Fabro environment still awaits an authorized representative run.

Remaining follow-up: iteration 066 remains `ready`; this kaizen fix neither retries the failed run nor authorizes a new delivery launch.
