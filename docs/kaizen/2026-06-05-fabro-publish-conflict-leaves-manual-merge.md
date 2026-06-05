# Problem: Fabro publish conflict left a manual merge to recover

Date: 2026-06-05

## Context

Fabro iteration implementation run `01KTCDPDG5SWTYBV8QQYVE9S5C` was delivering `docs/iterations/021-staff-area-redesign/plan.md` to `main`. The workflow had completed implementation, validation, `dev_check`, plan conformance, and final artifact checks before `publish_to_main` tried to squash the work and rebase it onto the latest `origin/main`.

## Expected standard

The iteration implementation workflow should either publish the validated implementation to `main`, or stop with a clear, safe recovery path that preserves the implementation evidence and makes the next operator action obvious. A failed publish should not leave the repository in an ambiguous merge state or require manual archaeology to understand what failed.

## What happened

The run failed at `publish_to_main` while rebasing the squashed implementation commit onto `origin/main`:

- Run ID: `01KTCDPDG5SWTYBV8QQYVE9S5C`
- Squash commit attempted by the workflow: `c62e011` (`iteration 021: Staff area redesign and read-only operations indexes`)
- Conflicted files reported by Fabro:
  - `web/lib/memba_web/live/admin/deliveries_live/index.ex`
  - `web/lib/memba_web/live/admin/messages_live/show.ex`
- Fabro then entered `publish_failed` with the summary: `Iteration implementation failed: could not squash and push the implementation to main. Check push credentials, branch protection, and whether origin/main moved with conflicts.`

The local repository is now on `rescue-021-merge` at `origin/main`, with the implementation changes staged in the index and conflict recovery left for a human/operator.

## Impact

The implementation appears validated but was not merged. Delivery is blocked until someone resolves or safely replays the publish. The failure also creates risk that a later operator could accidentally commit, drop, or partially merge the staged implementation while trying to recover.

## What allowed it to happen

The publish step depends on a late rebase after all implementation and validation work has completed. When `origin/main` moved with conflicting changes, the workflow could detect the conflict but did not provide an automated conflict-prevention gate, a branch/PR fallback, or a precise recovery command sequence.

The failure message lists broad possibilities, but the system weakness appears to be weak publish-time conflict handling and recovery guidance: the workflow can leave a large, validated change set in a manual merge/rescue state without a standard, low-risk handoff.

## Observations

- The conflict was discovered only at the final publish step, after `dev_check` and plan conformance had passed.
- The failed publish involved a large implementation commit: Fabro reported 30 files changed in the squash commit, while run inspection reported broader implementation summary evidence.
- The rescue state contains many staged product changes, so ordinary `git commit` or reset commands could have unintended consequences.
- The top-level failure message does not name the conflicted files; those details are in the `publish_to_main` failure output from run inspection.

## Why this matters

Late publish conflicts turn an otherwise validated automated delivery into manual recovery work. Without a standard recovery path, each failure requires fresh investigation and increases the chance of lost work, duplicated validation, or an unsafe merge.

## Open questions

- Did another Fabro run or human commit change the same admin LiveViews between the run start and publish step?
- Should Fabro retry by creating a PR/rescue branch when direct publish conflicts, rather than leaving a staged local rescue state?
- What is the safest standard command sequence for operators to recover this specific class of failed publish?

## Possible prevention ideas

- Add a pre-publish freshness/conflict gate before expensive final validation, or repeat it immediately before squash.
- On publish conflicts, automatically preserve the squash commit on a named branch and print exact next steps.
- Include conflicted file names and recovery branch/commit identifiers in the `publish_failed` summary.
- Prefer a PR fallback for conflicted publishes so review and conflict resolution happen in a normal GitHub workflow.
