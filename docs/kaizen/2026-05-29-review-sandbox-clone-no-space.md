# Problem: Iteration review sandbox clone failed with no space left on device

Date: 2026-05-29

Selected iteration: 003 Messaging skeleton
Plan path: docs/iterations/003-messaging-skeleton/plan.md
Implementation ref: 8fcf5e6
Base sha: 75c1d673cb9ee6c4247f605ac12fb32a62da884c

Fabro review run IDs:

- 01KSTRE5PPQXG7RDG0JHXF44YJ
- 01KSTREWPRHTGSGC5846WK73SQ

Web UI:

- https://fabro.home.wynne.family/runs/01KSTRE5PPQXG7RDG0JHXF44YJ
- https://fabro.home.wynne.family/runs/01KSTREWPRHTGSGC5846WK73SQ

Failed stage/status: sandbox initialization; run status FAILED.

Exact failure text:

```text
Failed to initialize sandbox
  caused by: Failed to clone repo into Docker sandbox: fatal: cannot create directory at 'docs/tools/fabro/public/integrations': No space left on device
warning: Clone succeeded, but checkout failed.
You can inspect what was checked out with 'git status'
and retry with 'git restore --source=HEAD :/'
```

Commands used:

```bash
bin/dev iteration-review review/003-messaging-skeleton docs/iterations/003-messaging-skeleton/plan.md 75c1d673cb9ee6c4247f605ac12fb32a62da884c
fabro system df
fabro system prune --older-than 1h --yes
fabro system prune --older-than 24h --yes
```

Observations:

- The implementation workflow for iteration 003 had already succeeded and published commit `8fcf5e6` to `main`.
- A review branch `review/003-messaging-skeleton` was created and pushed for the review command because the recorded implementation metadata used a commit SHA and `bin/dev iteration-review` requires a branch.
- The review run failed before any review stage executed, during Docker sandbox repository checkout.
- Retrying the same command produced the same sandbox initialization failure.
- Local disk space on the client machine was not exhausted, and the failure text came from the Fabro server-side Docker sandbox clone.
- `fabro system df` reported only Fabro storage usage, not the Docker filesystem that failed checkout.
- Attempts to run `fabro system prune` timed out after 30 seconds.
- This is a workflow/infrastructure failure rather than a code review or implementation failure.

Retry command after server-side Docker disk space is recovered:

```bash
bin/dev iteration-review review/003-messaging-skeleton docs/iterations/003-messaging-skeleton/plan.md 75c1d673cb9ee6c4247f605ac12fb32a62da884c
```

## Resolution

Date: 2026-05-31

Root cause: The original review attempts failed before review work began because the Fabro server-side Docker sandbox filesystem could not complete the repository checkout. The immediate blocker cleared operationally; this note records an incident rather than a remaining repository fix.

Fix applied:

- No repository code change was needed for this specific incident after the server-side sandbox could clone the repository again.
- Later review work for iteration 003 progressed past sandbox initialization, and iteration 003 was subsequently marked merged in commit `e635796`.

Validation:

- Read-only status check found later review run evidence at commit `50ad66c` showing `preflight_sandbox` succeeded after these failed attempts.
- Read-only status check confirmed `docs/iterations/003-messaging-skeleton/implementation.md` and `docs/iterations/README.md` record iteration 003 as merged.

Remaining follow-up:

- If Docker disk observability or automatic pruning is still desired, track it as a separate operational kaizen note.

