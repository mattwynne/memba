# Problem: Fabro sandbox files can be root-owned and block formatting

Date: 2026-06-23

## Context

During Fabro implementation run `01KVSMA9D18M6V47C2ZPQ9S83N` for iteration 044, the implementation agent spent time working around formatter failures that were caused by sandbox file ownership rather than product-code problems.

Relevant commands and paths:

```bash
bin/dev fabro deliver docs/iterations/044-conversation-page-alignment/plan.md --poll-interval 30
fabro events 01KVSMA9D18M6V47C2ZPQ9S83N --json
fabro logs 01KVSMA9D18M6V47C2ZPQ9S83N
bin/dev sandbox-check
```

Relevant files:

- `bin/dev`
- `.fabro/workflows/iteration-implementation/workflow.fabro`
- `devenv.nix`

## Expected standard

Tracked files in a Fabro sandbox should be writable by the same user that runs agent shell commands. Formatting should not fail because the sandbox checkout or checkpoint machinery left files owned by another user.

Sandbox preflight should catch repo-file writability problems before an implementation agent starts product work.

## What happened

The implementation agent reported that `mix format` could not rewrite touched files because they were not writable by the shell user.

Follow-up read-only investigation of run evidence found:

- agent shell commands ran as `user`;
- touched repo files were `root:root 644`;
- `mix format` failed with a permission error such as:

  ```text
  could not write to file ".../show_test.exs": permission denied
  ```

- `sudo chown` was not available in the sandbox:

  ```text
  sudo: /bin/sudo must be owned by uid 0 and have the setuid bit set
  ```

- directory ownership was `user:user`, so the agent worked around the problem by deleting/recreating files rather than rewriting them in place.

Current `bin/dev sandbox-check` checks runtime/cache directory writability, but it does not verify tracked repository-file writability before implementation starts.

## Impact

This is delivery-machinery friction. It consumes implementation-node time, makes formatting look like a product-code problem, and can push otherwise healthy work toward timeout. Because agents can sometimes work around it by recreating files, it may waste time in successful runs without being noticed.

## What allowed it to happen

- The Fabro Docker sandbox can present repository files with ownership that differs from the shell user used by agents.
- The sandbox image/config makes `/repos` and `/workspace` writable, but that does not guarantee cloned/checkpointed file ownership.
- The preflight path does not test whether representative tracked files are writable by the current shell user.
- There is no clear remediation path inside the sandbox when root-owned files appear, because `sudo` is unavailable.

## Observations

- This problem is separate from product-code validation failures.
- It should be fixed at the sandbox/provider boundary if possible: clone, checkpoint, and restore repo files as the same UID used by shell commands.
- A repository-side preflight guard would not solve the provider ownership problem, but it would make the abnormality fail early with a clear error instead of wasting implementation time.

## Why this matters

Formatting is part of the standard implementation loop. If formatting can be blocked by file ownership, every Fabro task that touches formatted files can pay a hidden tax or fail late for a non-product reason.

## Open questions

- Why did files become `root:root 644` while shell commands ran as `user`?
- Is the ownership change introduced by clone, checkpoint restore, image layering, or a Fabro sandbox copy operation?
- Can the Fabro Docker provider guarantee UID alignment for the working tree?

## Possible prevention ideas

- Fix the Fabro Docker provider or sandbox image so repo files are cloned/restored as the shell-command user.
- Add a `bin/dev sandbox-check` tracked-file writability check with owner diagnostics and clear remediation text.
- If Fabro supports a safe root prepare step, add a narrow ownership repair before agent nodes; treat this as a fallback because it may mask the provider-level bug.


## Resolution

Date: 2026-06-23

Root cause: `bin/dev sandbox-check` verified runtime/cache directories but did not verify that tracked repository files in the Fabro sandbox checkout were writable by the same UID running agent shell commands. A checkout or checkpoint restore could therefore leave tracked files `root:root 0644`, and the implementation agent would only discover the problem later when a formatter tried to rewrite a touched file.

Fix applied:

- `bin/dev`: extended `sandbox_check` with an early tracked-file writability scan over `git ls-files`. It now fails before setup/Postgres/test compile if any tracked file is not writable, prints numeric owner/group diagnostics for the first affected files, explains the likely Fabro sandbox/provider UID mismatch, and tells the operator to repair ownership instead of spending implementation time on formatter workarounds.
- `docs/kaizen/2026-06-23-fabro-sandbox-root-owned-files-block-format.md`: recorded this resolution.

Validation:

- `bash -n bin/dev` — shell syntax is valid.
- `rg -n "check_tracked_repo_file_writability|Current user:|Tracked repository file writability OK" bin/dev` — confirmed the early ownership guard and diagnostics are present.

Remaining follow-up:

- The repository-side guard fails early and clearly, but the provider-level cause still needs to be fixed in Fabro if root-owned checkout/checkpoint files recur.
