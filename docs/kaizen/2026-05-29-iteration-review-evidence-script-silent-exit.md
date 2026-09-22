# Kaizen: iteration review evidence collection can fail silently before diagnostics

Date: 2026-05-29

## Context

After a fix for iteration-review run-branch handling, we retried reviewing iteration 002.

Implementation metadata:

```text
Branch: fabro/run/01KST2YJGFYEGE4CAR6JK5JF8H
Pull request: none
Base ref: origin/main
Status: ready-for-review
```

Review command:

```bash
bin/dev iteration-review \
  fabro/run/01KST2YJGFYEGE4CAR6JK5JF8H \
  docs/iterations/002-membership-model/plan.md \
  origin/main
```

Review run:

```text
01KSTCHPWKVZDC7J8V21EXS0FE
```

Web UI:

```text
https://fabro.home.wynne.family/runs/01KSTCHPWKVZDC7J8V21EXS0FE
```

The prior failure mode, where a detached worktree caused Fabro to clone remote branch `HEAD`, was fixed. The command now created a local tracking branch and printed useful diagnostics before invoking Fabro:

```text
Review branch: fabro/run/01KST2YJGFYEGE4CAR6JK5JF8H
Review HEAD: 31c69dd95de9ed035a6054a856bf56bb795d1258
Review upstream: origin/fabro/run/01KST2YJGFYEGE4CAR6JK5JF8H
```

Fabro sandbox clone succeeded.

## What happened

The review workflow got further than before:

```text
✓ Start
✓ Read Iteration Plan
✓ Preflight Review Sandbox
✓ Run Dev Check
✗ Collect Implementation Evidence
```

`dev check` passed in the review sandbox.

Then `Collect Implementation Evidence` failed with exit code 1 and **no command output**:

```text
✗ Collect Implementation Evidence
Error: Script failed with exit code: 1
```

Event log detail:

```text
command.completed ... node_id="collect_implementation_evidence" ... exit_code=1 ... output_bytes=0
stage.failed ... message="Script failed with exit code: 1"
```

This means the evidence script exited before its first diagnostic line:

```bash
echo '=== Implementation Evidence ==='
```

So the failure occurred in the preamble before evidence printing, most likely one of:

```bash
if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then ... fi
...
if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
  echo "Configured base_ref is not a valid ref: $base_ref" >&2
  exit 1
fi
...
merge_base=$(git merge-base HEAD "$base_ref")
```

Because stdout/stderr were captured and `output_bytes=0`, even the explicit invalid-base error did not run. That points most strongly at an unguarded command substitution under `set -e`, especially:

```bash
merge_base=$(git merge-base HEAD "$base_ref")
```

If `git merge-base` returns non-zero, the shell exits immediately without printing diagnostics.

## The problem

The evidence script still has a silent-failure path before it prints the implementation evidence header or any structured diagnostics.

This makes the review workflow hard to operate. The operator can see that:

- the review branch exists;
- the sandbox cloned it;
- `dev check` passed;
- the base ref input was `origin/main`;

but cannot see:

- whether `origin/main` resolved inside the sandbox;
- whether `HEAD` and `origin/main` have a merge base;
- what refs were available;
- what branch Fabro actually checked out in the sandbox;
- why evidence collection exited.

The workflow therefore fails before the actual review gates without enough information to fix or retry confidently.

## Why this matters

Iteration review is the quality gate between implementation and merge. It needs to be more observable than normal implementation stages, not less.

A failure in evidence collection should never be silent. If the workflow cannot compare the implementation branch with the base, it should print a complete Git diagnostic bundle before exiting.

Without that, we burn a full sandbox setup and dev check only to learn that a pre-review shell script exited somewhere.

## Suspected root cause

Likely root cause: `git merge-base HEAD origin/main` failed in the review sandbox.

Possible reasons:

1. The sandbox cloned only the implementation branch with shallow history, so it did not have enough history to find a merge base with `origin/main`.
2. `origin/main` was not actually present despite the fetch logic.
3. The implementation branch (`fabro/run/...`) is made of Fabro checkpoint commits whose ancestry does not connect to the fetched `origin/main` in the shallow clone.
4. The script runs with `set -e`, so command substitution failure exits without diagnostics.

The run output supports this because evidence collection produced zero bytes: no header, no invalid-base message, no Git status, no branch list.

## Desired behaviour

Evidence collection should be deliberately diagnostic-first.

Before any command that can terminate the script, it should print:

```text
=== Implementation Evidence Debug ===
PWD: ...
Branch: ...
HEAD: ...
Base ref input: origin/main
Available branches:
...
Available remote branches:
...
Recent commits:
...
```

Then it should resolve the base ref and merge base with guarded commands:

```bash
if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
  echo "Base ref does not resolve: $base_ref" >&2
  git branch -a -vv >&2 || true
  git show-ref --heads --remotes >&2 || true
  exit 1
fi

if ! merge_base=$(git merge-base HEAD "$base_ref" 2>/tmp/merge-base.err); then
  echo "Could not compute merge base between HEAD and $base_ref" >&2
  cat /tmp/merge-base.err >&2 || true
  git log --oneline --decorate --max-count=20 --all >&2 || true
  git branch -a -vv >&2 || true
  git show-ref --heads --remotes >&2 || true
  exit 1
fi
```

If a merge base cannot be found because of shallow history, the script should try a deeper fetch before failing:

```bash
git fetch --quiet --deepen=100 origin "$base_branch" || true
```

or simply unshallow/fetch enough refs for review:

```bash
git fetch --quiet --unshallow origin || true
```

## Questions to answer

1. Did `git merge-base HEAD origin/main` fail in the sandbox?
2. Is the review sandbox clone shallow, and does that explain the missing merge base?
3. Should iteration-review force a full-history fetch for the implementation branch and base branch before evidence collection?
4. Are Fabro run branch checkpoint commits connected to `origin/main`, or do they need a different diff strategy?
5. Should `base_ref` be compared directly (`git diff origin/main..HEAD`) when merge-base fails, or is a merge base required?
6. Should the review workflow accept a raw implementation run branch and derive its true base commit from Fabro metadata instead of Git ancestry?

## Suggested fixes

### Make evidence collection diagnostic-first

Move a basic diagnostic header to the top of the script, before base resolution and merge-base calculation.

### Guard all Git resolution commands

Do not allow `set -e` command substitutions to exit without context. Wrap `git merge-base`, `git rev-parse`, `git diff`, and fetches with explicit `if ! ...; then` diagnostics.

### Fetch enough history

Before computing the merge base, fetch both:

```bash
git fetch --quiet origin main:refs/remotes/origin/main || true
git fetch --quiet origin fabro/run/01KST2YJGFYEGE4CAR6JK5JF8H:refs/remotes/origin/fabro/run/01KST2YJGFYEGE4CAR6JK5JF8H || true
```

If still no merge base, deepen or unshallow.

### Support run-branch-specific diffing

If Fabro run branches have unusual ancestry, use a diff strategy based on known base SHA or workflow input rather than assuming `git merge-base HEAD origin/main` works.

For example, review handoff metadata could record:

```text
Base sha: <sha at implementation run start>
Implementation sha: <final run sha>
```

Then evidence collection can diff exactly:

```bash
git diff --stat "$base_sha".."$implementation_sha"
```

## Resolution

Implemented in `.fabro/workflows/iteration-review/workflow.fabro`.

The `Collect Implementation Evidence` script is now diagnostic-first. It prints a debug header before any base-ref or merge-base work:

```text
=== Implementation Evidence Debug ===
PWD: ...
Branch: ...
HEAD: ...
Base ref input: ...
--- available branches ---
--- available remote branches ---
--- recent commits ---
```

The script now guards the previously silent failure points:

- invalid or missing `base_ref` now prints branch and ref diagnostics before exiting;
- `git merge-base HEAD "$base_ref"` is wrapped in an explicit `if ! ...; then` block;
- if merge-base calculation fails, the script prints whether the repository is shallow;
- for shallow repositories, it tries to deepen the fetch and then unshallow before failing;
- if merge-base still cannot be computed, it prints recent commits, all branches, and all refs;
- `git diff --stat`, `git diff --name-status`, and `git diff --name-only` are guarded so diff failures report context instead of relying on `set -e`.

This preserves the requirement that evidence collection should fail when it cannot establish a valid implementation diff, but makes the failure actionable.

## Verification

Reproduced the old failure mode in a temporary Git repository with disconnected branch history. The previous script exited with code 1 and produced zero stdout/stderr bytes, matching the observed Fabro run failure.

Ran the updated script against the same disconnected-history setup. It still exited with code 1, as expected, but printed the debug header, available branches, recent commits, shallow-repository status, and refs. This confirms the silent-exit path is closed.

Ran the updated script against normal branch history. Evidence collection succeeded and printed the implementation evidence, diff stat, name-status, and excerpt-filter result.

Ran the project quality gate:

```bash
bin/dev check
```

Result:

```text
30 tests, 0 failures
```

## Current takeaway

The previous branch-handling fix solved the sandbox clone problem, and evidence collection now fails with useful diagnostics instead of silently exiting before the header. A future improvement may still be needed if Fabro run branches are intentionally disconnected from `origin/main`; that would require a base-SHA or run-metadata diff strategy rather than relying only on Git ancestry.
