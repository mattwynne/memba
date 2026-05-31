# Problem: Fabro implementation run required manual rescue after publish failure

Date: 2026-05-30

## Context

We were rescuing implementation work from Fabro run `01KSXZQ3ZR4RBHVZKG5ZARSE32` for `docs/iterations/006-browser-cucumber-automation/plan.md`.

The run had completed implementation, validation, `npm test` in `acceptance-tests/`, `dev check`, and plan conformance, but did not publish to `main`.

## What happened

The run failed at `Publish Implementation to Main` with:

```text
Refusing to publish implementation: locked acceptance feature files changed.
acceptance-tests/features/operator_email_deliverability.feature
```

At the same time, Fabro repeatedly warned that it could not push the run branch:

```text
Failed to push run branch fabro/run/01KSXZQ3ZR4RBHVZKG5ZARSE32
```

The event log showed GitHub rejected the run branch because the checkpoint history contained an oversized file:

```text
File acceptance-tests/core is 252.54 MB; this exceeds GitHub's file size limit of 100.00 MB
GH001: Large files detected.
```

Manual rescue was needed. The rescue recovered the implementation patch, restored the necessary `@todo-web` feature tag, fixed local harness drift around `bin/dev up`, aligned Playwright with the Nix browser revision, re-ran validation, merged a clean commit to `main`, and pushed with HTTPS after SSH push failed.

## Observations

- The publish failure hid otherwise valid implementation work behind a final gate failure.
- The locked-feature guard was too blunt for this iteration: the plan explicitly allowed a narrow browser partition tag, but the final publish script rejected the changed `.feature` file.
- The run branch could not be pushed because a generated `acceptance-tests/core` file had entered checkpoint history before `.gitignore` was updated.
- Because the run branch push failed, recovering the final state depended on local Fabro metadata/events and manual patch reconstruction rather than simply checking out a remote branch.
- The rescued code also exposed drift between the browser lifecycle and current `bin/dev up`: `bin/dev up` starts Phoenix and does not return, so using it as a Postgres-readiness command caused local acceptance runs to time out.
- Local validation exposed Playwright/Nix browser revision mismatch when package versions drifted away from `pkgs.playwright-driver.browsers`.

## Why this matters

A successful implementation can become expensive to recover if the publish gate, checkpoint branch push, and local validation environment each fail in different ways. This creates avoidable manual archaeology and increases the risk of losing or mis-merging valid work.

## Open questions

- Should the implementation publish guard allow explicitly planned acceptance-tag changes, or require an explicit workflow input for permitted `.feature` edits?
- Should Fabro prevent oversized generated files from entering checkpoint history before attempting to push run branches?
- Should the acceptance harness have a first-class `bin/dev postgres`/service-readiness contract documented before implementation workflows depend on it?
- Should `devenv.nix` or acceptance tests assert that the installed Playwright package version matches `pkgs.playwright-driver.browsers`?

## Resolution options

Date: 2026-05-30

Root cause: This was not primarily an upstream-main drift problem. The implementation publish script already fetches `origin/main` and runs `git pull --rebase origin main` before pushing. The expensive rescue came from two earlier resilience gaps: the final publish guard had no way to distinguish an explicitly planned acceptance tag-only edit from an accidental `.feature` change, and Fabro checkpoint history already contained an oversized generated `acceptance-tests/core` file, so the run branch could not be pushed for normal recovery.

Options:

1. Add an explicit planned feature-edit allowance — for example a workflow input or plan metadata listing allowed `.feature` files and restricting their diffs to tag-only changes. Benefit: keeps the locked-feature guard while allowing iterations like browser partitioning. Cost/risk: adds policy surface and must avoid becoming a broad bypass.
2. Add a checkpoint-size/generated-file defence — at minimum keep `acceptance-tests/core` ignored/excluded and prefer running acceptance tests through a wrapper that disables/removes core dumps; ideally Fabro itself should reject or skip blobs over the remote host limit before checkpoint commits enter history. Benefit: preserves pushed run branches for recovery. Cost/risk: repository-side guards cannot fully protect against files created inside arbitrary agent commands immediately before Fabro checkpoints.
3. Rebase earlier, before final validation — fetch/rebase onto current `origin/main` before `dev ci` and plan conformance, not only inside publish. Benefit: validates the final implementation against current trunk and surfaces conflicts before the last publish step. Cost/risk: does not address the observed locked-feature or oversized-blob failures; conflict handling still needs a clear stop/resume path.
4. Make recovery independent of remote run-branch push — document a deterministic local rescue command that extracts the final checkpoint patch from Fabro metadata/events when `origin/fabro/run/<id>` is unavailable. Benefit: reduces archaeology when the remote branch cannot be pushed. Cost/risk: fallback only; it does not prevent the failure.

Recommendation: implement options 1 and 2 first. Add option 3 as a nice hardening step because it moves trunk-drift conflicts earlier, but do not expect rebasing alone to prevent this class of rescue. Option 4 is useful documentation after the preventive fixes.

Validation plan:

- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml` after any workflow-input or guard changes.
- A targeted shell test for allowed tag-only feature diffs versus rejected scenario-text feature diffs.
- A smoke run or local script check proving `acceptance-tests/core` is ignored/excluded and not present in publish/checkpoint candidate paths.

Status: awaiting decision.
