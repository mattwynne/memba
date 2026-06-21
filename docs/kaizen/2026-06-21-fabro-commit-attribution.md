# Problem: Fabro-published commits are attributed to the GitHub user `fabro`

Date: 2026-06-21

## Context

Matt observed that GitHub commit history for this repository shows commits attributed to a user called `fabro`, for example:

https://github.com/mattwynne/memba/commits?author=fabro

This affects the delivery machinery around Fabro workflow commits and publication steps, not ordinary product code behavior.

## Expected standard

Commits that land on `main` should have clear, intentional attribution. If automation publishes commits, the author/committer identity should be an approved project identity and should not make GitHub history look like work was authored by an unexpected or unrelated user.

## What happened

Recent commits on `origin/main` match `--author=fabro`. Local inspection showed examples such as:

```text
d48758270  Fabro <noreply@fabro.sh>              Fabro <fabro@users.noreply.github.com>  fabro(01KVNM68WX9Z56FVEWAGK1BW3V): synthesis_gate (succeeded)
3e44b68f8  Fabro <fabro@users.noreply.github.com> Fabro <fabro@users.noreply.github.com> Mark iteration plan validated
8e7d40031  Fabro <fabro@users.noreply.github.com> Fabro <fabro@users.noreply.github.com> iteration 040: Follow a conversation, and send replies only to followers
```

The repository workflows include hard-coded Git identities in publish/finalization scripts:

- `.fabro/workflows/iteration-implementation/scripts/publish_to_main.sh`
- `.fabro/workflows/iteration-review/scripts/finalize_iteration_status.sh`
- `.fabro/workflows/iteration-review/scripts/publish_polish_to_main.sh`
- `.fabro/workflows/plan-validation/scripts/publish_ready.sh`

Each configures `user.name` as `Fabro` and uses `fabro@users.noreply.github.com` for commits that can be pushed to the shared repository history.

## Impact

This creates audit and ownership confusion in GitHub history. Product and workflow state changes can appear to be authored by an unexpected `fabro` identity rather than by Matt or by a clearly approved bot identity for this repository. It also makes GitHub author filters and contribution views misleading.

Severity: quality and traceability risk. It does not appear to block delivery immediately, but it affects every automated publish step until fixed.

## What allowed it to happen

The workflow publish scripts set their own Git author/committer identity locally and push commits without a guardrail checking that the resulting identity matches the repository's expected attribution policy.

There also appears to be no documented standard for which identity Fabro should use when committing to this repository, and no preflight/CI check that flags unapproved author or committer emails before changes land on `main`.

## Observations

- The local user Git config is `Matt Wynne <matt@mattwynne.net>`, so the unexpected attribution is not coming from Matt's normal global Git identity.
- `git log origin/main --author=fabro` returns recent Fabro workflow, plan-validation, review, and iteration publish commits.
- The scripts above explicitly run `git config user.name "Fabro"` and `git config user.email "fabro@users.noreply.github.com"` before committing.
- Some Fabro checkpoint commits also use `Fabro <noreply@fabro.sh>`, which means there may be more than one automation identity involved.

## Why this matters

Commit attribution is part of the delivery system's audit trail. If automated commits use an unexpected GitHub identity, future investigation has to distinguish real authorship, automation provenance, and GitHub account mapping after the fact. That weakens trust in the history and makes regressions or workflow changes harder to trace.

## Open questions

- What exact author and committer identity should Fabro use for commits that land on `main`?
- Should workflow checkpoint commits and final publish commits use the same identity or distinct approved identities?
- Are existing commits worth rewriting, or is the fix only for future commits?

## Possible prevention ideas

- Document the approved Git identities for human, Fabro checkpoint, and Fabro publish commits.
- Centralize Fabro Git identity setup in one helper instead of hard-coding it in multiple scripts.
- Add a publish-time or CI guard that fails when commits destined for `main` use an unapproved author or committer email.

## Resolution

Date: 2026-06-21

Root cause: Memba's Fabro publish/finalization scripts persistently wrote `user.name=Fabro` and `user.email=fabro@users.noreply.github.com` into the sandbox repository with `git config`. That address maps commits to the GitHub user `fabro`. Because the config was persistent, it could also leak into later Fabro checkpoint commits in the same sandbox, producing commits with `Fabro <noreply@fabro.sh>` as author but `Fabro <fabro@users.noreply.github.com>` as committer.

Fix applied:

- `.fabro/workflows/scripts/git_identity.sh`: added a scoped `fabro_git_commit` helper that sets author/committer identity only for the single `git commit` command. The default identity is `Fabro <noreply@fabro.sh>` and can be overridden with `FABRO_GIT_AUTHOR_*` / `FABRO_GIT_COMMITTER_*` environment variables.
- `.fabro/workflows/iteration-implementation/scripts/publish_to_main.sh`: replaced persistent `git config` with the scoped helper.
- `.fabro/workflows/iteration-review/scripts/finalize_iteration_status.sh`: replaced persistent `git config` with the scoped helper.
- `.fabro/workflows/iteration-review/scripts/publish_polish_to_main.sh`: replaced persistent `git config` with the scoped helper.
- `.fabro/workflows/plan-validation/scripts/publish_ready.sh`: replaced persistent `git config` with the scoped helper.
- `.fabro/workflows/iteration-implementation/scripts/test_publish_to_main.sh`: added assertions that published commits use `Fabro <noreply@fabro.sh>` and that the script does not mutate repo-local Git identity.
- `.fabro/workflows/scripts/test_git_identity.sh`: added a focused regression test for the helper and a scan that fails if Fabro workflow files reintroduce `fabro@users.noreply.github.com`.
- `.fabro/workflows/plan-validation/test.sh`: added the shared identity helper to the tracked/pushed input guard for plan-validation runs.
- `.fabro/workflows/README.md`: documented that Fabro publish/finalization scripts must use the scoped identity helper rather than changing repo-local Git config.

Validation:

- `bash .fabro/workflows/scripts/test_git_identity.sh` — passed.
- `bash .fabro/workflows/iteration-implementation/scripts/test_publish_to_main.sh` — passed.
- `bash .fabro/workflows/iteration-review/scripts/test_finalize_iteration_status.sh` — passed.
- `bash -n .fabro/workflows/scripts/git_identity.sh .fabro/workflows/scripts/test_git_identity.sh .fabro/workflows/iteration-implementation/scripts/publish_to_main.sh .fabro/workflows/iteration-review/scripts/finalize_iteration_status.sh .fabro/workflows/iteration-review/scripts/publish_polish_to_main.sh .fabro/workflows/plan-validation/scripts/publish_ready.sh .fabro/workflows/iteration-implementation/scripts/test_publish_to_main.sh .fabro/workflows/iteration-review/scripts/test_finalize_iteration_status.sh .fabro/workflows/plan-validation/test.sh` — passed.
- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml --no-upgrade-check` — passed with existing goal-gate retry warnings.
- `fabro validate .fabro/workflows/iteration-review/workflow.toml --no-upgrade-check` — passed with existing goal-gate retry warnings.
- `fabro validate .fabro/workflows/plan-validation/workflow.toml --no-upgrade-check` — passed.
- `./bin/dev check` — passed.

Remaining follow-up:

- Existing history still contains commits already attributed to `fabro@users.noreply.github.com`; this fix only prevents future workflow commits from using that GitHub-user-mapped address.
