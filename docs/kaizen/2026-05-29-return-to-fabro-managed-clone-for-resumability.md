# Plan: return iteration implementation to Fabro-managed clone and run branches

Date: 2026-05-29

## Context

The latest resumability kaizen exposed a mismatch between the workflow contract and the checkout the workflow starts from:

- `docs/kaizen/2026-05-28-resumable-iteration-implementation.md` said a new implementation run with the same `plan_path` should reuse durable task commits and the existing iteration `todo.md`.
- `docs/kaizen/2026-05-29-resume-contract-gap-between-checkpoints-and-branches.md` showed that this did not happen. The fresh run manually cloned `main`, could not see the failed run's task commits or `todo.md`, regenerated `todo.md`, and started again at task 001.

This raised the question: if Fabro already has a predictable run branch, why did our workflow not use it?

The answer is Chesterton's fence. The manual clone path was not arbitrary. It was introduced while debugging early Docker sandbox failures.

## Why the manual clone fence exists

The manual clone strategy was introduced in commit `a71828b` (`Clone Memba during Fabro prepare`). It added:

```toml
[run.clone]
enabled = false
```

and moved repository checkout into explicit `[[run.prepare.steps]]`.

The detailed history is in:

- `docs/notes/2026-05-27-fabro-sandbox-debugging-lessons.md`
- `docs/retros/2026-05-27.md`
- `docs/retros/2026-05-27-fabro-sandbox-followup.md`
- `docs/reference/fabro-devenv.md`

The relevant lesson from `docs/notes/2026-05-27-fabro-sandbox-debugging-lessons.md` was:

> The useful breakthrough was disabling built-in clone and moving checkout into `[[run.prepare.steps]]`.
>
> That changed the failure mode from opaque sandbox initialization failure to observable setup-command failure. Once the sandbox reached `sandbox.ready`, `sandbox.initialized`, and `setup.started`, `--preserve-sandbox`, Docker events, Docker logs, and `docker inspect` became useful.

So the fence was observability. Built-in clone failures happened too early and hid too much.

The early failures included:

1. `git` was not available on the image's default execution path before `devenv shell`.
2. `/repos` and `/workspace` were not writable by the non-root runtime user.
3. HTTPS clone lacked CA certificates before shell startup.
4. The image baked in `/workspace/memba`, blocking Fabro's desired symlink.
5. Clone stderr was misleading; Fabro surfaced only `Cloning into ...` for failures.
6. GitHub token clone URLs could fail where public unauthenticated clone would work.
7. The generated devenv entrypoint exited and killed in-flight `docker exec` prepare commands with exit code 137.

Those were real problems. We should not remove the workaround unless the original problems are gone.

## Current image fixes that change the trade-off

The current `devenv.nix` and `docs/reference/fabro-devenv.md` show that the sandbox image now includes the fixes that the original workaround helped us discover:

- `/bin/git` is available before `devenv shell`.
- The `git` wrapper adds `--quiet` to clone and strips embedded GitHub credentials for public clone URLs.
- `/repos` and `/workspace` exist and are writable by UID/GID 1000.
- `SSL_CERT_FILE` and `NIX_SSL_CERT_FILE` point at CA certificates.
- `workingDir = "/workspace"`, so the image does not pre-create `/workspace/memba`.
- `entrypoint = []` and `startupCommand = [ "/bin/bash" "-lc" "sleep infinity" ]`, so Fabro's run container stays alive.
- The devenv wrapper resets baked `/env` state and provides writable runtime cache locations.

Because these image-level fixes are now in place, the old reason to bypass Fabro-managed clone may no longer apply.

## Smoke test performed

I tested Fabro-managed clone using a temporary smoke workflow.

### Failed first attempt: explicit `working_dir` suppresses clone source detection

A smoke workflow with this setting:

```toml
[run]
working_dir = "/workspace/memba"
```

and no manual clone caused preflight/runtime to behave as if there were no clone source:

```text
Git: unknown
No clone source present; sandbox workspace will be empty
repo_cloned: false
```

The run entered `/workspace`, which was not a Git repository.

This is an important gotcha: do not explicitly override `working_dir` when relying on Fabro's repository detection and managed clone.

### Successful smoke test: remove `working_dir`, let Fabro infer the repo

I then created a temporary pushed branch `clonesmoketest` containing a minimal workflow with no manual clone and no `working_dir` override.

Run:

```text
01KSRMFG9T97ZV3TXNYFHG7047
```

Result: succeeded.

Key evidence from `fabro inspect` / `fabro dump`:

```json
"repo_cloned": true,
"clone_origin_url": "https://github.com/mattwynne/memba",
"clone_branch": "clonesmoketest",
"primary_repo_path": "/repos/mattwynne/memba",
"primary_repo_link": "/workspace/memba"
```

Fabro created and checked out a run branch:

```text
fabro/run/01KSRMFG9T97ZV3TXNYFHG7047
```

Inside the run:

```text
PWD=/repos/mattwynne/memba
--- branch ---
fabro/run/01KSRMFG9T97ZV3TXNYFHG7047
--- HEAD ---
0299147 Remove smoke working_dir override
```

Fabro checkpointed with Git commit SHAs:

```json
"git_commit_sha": "f01dd955230d197a1292659531ebcab6ef3daeb5"
```

Fabro pushed the run branch after checkpoints:

```json
{
  "event": "git.push",
  "properties": {
    "branch": "refs/heads/fabro/run/01KSRMFG9T97ZV3TXNYFHG7047:refs/heads/fabro/run/01KSRMFG9T97ZV3TXNYFHG7047",
    "success": true
  }
}
```

The remote branch exists:

```bash
git ls-remote --heads origin 'fabro/run/01KSRMFG9T97ZV3TXNYFHG7047'
```

returned:

```text
385ea51a5caa5c9c9c9a8d7d633987c67928e78a refs/heads/fabro/run/01KSRMFG9T97ZV3TXNYFHG7047
```

The smoke run also produced `final_git_commit_sha` and a final diff, proving the missing `git_commit_sha` problem is tied to our manual clone path, not inherent to the Docker environment.

The temporary source branches used for the test were deleted. The Fabro run branch was left as evidence.

## Conclusion

The old manual clone strategy solved a real sandbox observability problem, but it now blocks resumability:

- Fabro cannot infer repository state cleanly.
- `repo_cloned` is false.
- checkpoints lack `git_commit_sha`.
- no usable `fabro/run/...` branch is pushed for failed implementation runs.
- fresh runs manually clone `main` and lose prior task commits plus `todo.md`.

Fabro-managed clone now works with the current image, provided we do not override `working_dir`.

Therefore the right next move is to return `iteration-implementation` to Fabro-managed clone and let Fabro own the run branch.

## Proposed production change

Edit `.fabro/workflows/iteration-implementation/workflow.toml`.

### Remove explicit working directory

Remove:

```toml
[run]
working_dir = "/workspace"
```

Keep the goal, but let Fabro infer the repository working directory.

### Remove manual clone disablement

Remove:

```toml
[run.clone]
enabled = false
```

### Remove manual checkout prepare steps

Remove these prepare steps:

```toml
[[run.prepare.steps]]
command = ["mkdir", "-p", "/workspace"]

[[run.prepare.steps]]
command = ["git", "clone", "--branch", "main", "--single-branch", "--depth", "10", "--no-tags", "https://github.com/mattwynne/memba", "/workspace"]

[[run.prepare.steps]]
command = ["git", "-C", "/workspace", "config", "user.email", "fabro@example.invalid"]

[[run.prepare.steps]]
command = ["git", "-C", "/workspace", "config", "user.name", "Fabro"]
```

Fabro-managed clone should create `/repos/mattwynne/memba`, link `/workspace/memba`, check out `fabro/run/<run-id>`, and set checkpoint/run-branch metadata.

### Keep Mix bootstrap, but point it at Fabro-managed checkout

Change:

```toml
[[run.prepare.steps]]
command = ["bash", "/workspace/.fabro/workflows/iteration-implementation/prepare_mix.sh"]
```

to:

```toml
[[run.prepare.steps]]
command = ["bash", "/workspace/memba/.fabro/workflows/iteration-implementation/prepare_mix.sh"]
```

or, if Fabro prepare commands run in the inferred repository directory, prefer a relative path after confirming with a tiny preflight run:

```toml
[[run.prepare.steps]]
command = ["bash", ".fabro/workflows/iteration-implementation/prepare_mix.sh"]
```

The smoke test showed node scripts run with `PWD=/repos/mattwynne/memba`, while the sandbox metadata link is `/workspace/memba`. The absolute symlink path is probably safest for prepare.

### Apply the same clone cleanup to `iteration-review`

`.fabro/workflows/iteration-review/workflow.toml` currently has the same manual clone pattern. Once implementation is fixed, apply the same managed-clone strategy there too, so review runs can start from a run branch or implementation branch instead of always cloning `main`.

## Expected recovery model after the change

A normal implementation run should start like this:

1. Fabro clones the source branch.
2. Fabro creates `fabro/run/<run-id>` from the source branch.
3. `iteration-implementation` drains tasks.
4. `commit_task` creates one task commit per validated task.
5. Fabro checkpointing records `git_commit_sha` and pushes the run branch.
6. If the run fails mid-iteration, the pushed run branch contains task commits and `todo.md`.

Recovery then has two viable paths:

### Path A: fork/resume from Fabro checkpoint

With `git_commit_sha` present, `fabro fork <run>` should be able to reconstruct a run from a checkpoint. `fabro resume <run>` should also be less brittle, though it still uses the old captured workflow definition.

### Path B: fresh run from the previous run branch

A fresh run should be started from the prior run branch when we want to use the latest workflow definition but retain implementation progress.

The exact CLI for this still needs to be confirmed. It may be as simple as checking out the run branch locally before invoking Fabro, or Fabro may need an explicit base/ref input if workflow invocation always uses local branch context.

The important difference is that the progress branch will now exist and be pushed.

## Acceptance criteria

- `fabro preflight .fabro/workflows/iteration-implementation/workflow.toml` reports a clean Git repository and no `No clone source present` warning.
- A smoke run of `iteration-implementation` with a deliberately missing `plan_path` reaches the workflow's `read_plan` failure, not sandbox clone/setup failure.
- `fabro inspect <run>` for that smoke run reports:
  - `repo_cloned: true`
  - `clone_branch` set to the source branch
  - `primary_repo_path: /repos/mattwynne/memba`
  - `primary_repo_link: /workspace/memba`
  - `start_record.run_branch: fabro/run/<run-id>`
  - `start_record.base_sha` set
- Checkpoint events include `git_commit_sha`.
- Events include successful `git.push` to `refs/heads/fabro/run/<run-id>`.
- `git ls-remote --heads origin fabro/run/<run-id>` finds the run branch.
- A controlled failure after at least one task commit leaves a pushed run branch containing:
  - the task commit;
  - the updated iteration `todo.md`.
- A follow-up recovery rehearsal starts from that branch and does not reimplement completed tasks.
- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml` passes.
- `PATH="$PWD/bin:$PATH" dev check` passes locally after workflow/docs edits.

## Regression risks

### Risk: the original opaque built-in clone failures return

Mitigation: the image now contains all fixes discovered during the original debugging. First run should be a small smoke run with `--preserve-sandbox` and a missing `plan_path`, not a long implementation run.

### Risk: prepare commands run before `/workspace/memba` exists

Mitigation: test with the smoke run. If prepare commands execute after clone, `/workspace/memba/.fabro/.../prepare_mix.sh` should exist. If not, use a relative path or adjust prepare ordering according to observed Fabro behavior.

### Risk: explicit `working_dir` gets reintroduced

Mitigation: document the gotcha in `.fabro/workflows/README.md` and this kaizen. Preflight should catch it: `Git: unknown` and `No clone source present` mean we have broken Fabro's repository detection.

### Risk: branch recovery command remains unclear

Mitigation: after managed clone is restored, run a recovery rehearsal and document the exact operator command. The prior README statement, “Resume with a new `fabro run` using the same `plan_path`,” is incomplete unless the new run starts from the prior run branch.

## Implementation tasks

1. Edit `iteration-implementation/workflow.toml` to remove manual clone and `working_dir` override.
2. Point `prepare_mix.sh` at the Fabro-managed checkout.
3. Run `fabro validate` and `fabro preflight`.
4. Run a missing-plan smoke test with `--preserve-sandbox`.
5. Inspect smoke run metadata and confirm `repo_cloned`, `run_branch`, `base_sha`, `git_commit_sha`, and pushed run branch.
6. Apply the same cleanup to `iteration-review/workflow.toml` if the implementation smoke test succeeds.
7. Update `.fabro/workflows/README.md` with:
   - the managed-clone contract;
   - the `working_dir` gotcha;
   - the exact recovery command once rehearsed.
8. Run local `dev check`.
9. Commit the workflow and documentation changes.

## Current recommendation

Proceed with the managed-clone restoration. The smoke test shows it gives us exactly the missing pieces: a pushed `fabro/run/<run-id>` branch and checkpoint `git_commit_sha`. That aligns the workflow with Fabro's native recovery model instead of maintaining a parallel manual clone strategy that now undermines resumability.
