# 2026-05-27 Fabro sandbox follow-up notes

## Context

We were trying to get the Fabro `iteration-implementation` workflow to run for:

```sh
fabro run .fabro/workflows/iteration-implementation/workflow.toml -I plan_path=docs/iterations/001-member-message-deliverability/plan.md
```

Previous notes are in `docs/retros/2026-05-27.md`.

## Changes made and pushed

Commits pushed after the first retro:

- `610a6ae` Quiet Fabro sandbox git clone
- `59d388c` Make Fabro git clone tolerate token URLs
- `a71828b` Clone Memba during Fabro prepare
- `1034de5` Use script for Fabro prepare clone
- `a76a4b9` Split Fabro prepare checkout steps
- `e3b71fb` Allow clone progress during Fabro prepare
- `e509cb7` Use default Fabro Docker resources

Current local repo state was clean after these commits were pushed.

## Important SSH note

Matt pointed out that he has an SSH key for the server and that agent forwarding should be used.

The `hub.local` helper `bin/console` currently disables the local SSH agent with:

```sh
-o IdentityAgent=none
```

So `PATH="$PWD/bin:$PATH" devenv shell -- console fabro ...` does not forward Matt's agent.

A direct SSH command with `-A` and the `hub.local` container key can forward the agent, but during this session `ssh-add -l` reported:

```text
The agent has no identities.
```

Despite that, an SSH test from the Fabro container to GitHub succeeded at one point using available auth:

```text
Hi mattwynne! You've successfully authenticated, but GitHub does not provide shell access.
```

When using `console fabro`, I often had to set `SSH_AUTH_SOCK=` to stop the harness/broken local agent from interfering with the container key:

```sh
cd /Users/matt/git/mattwynne/hub.local
SSH_AUTH_SOCK= PATH="$PWD/bin:$PATH" devenv shell -- console fabro "..."
```

If the next agent needs true agent forwarding, do not use `console fabro` as-is. Either patch/override the helper or run direct `ssh -A ...` with the right route/key.

## What changed in the image

`devenv.nix` now creates a wrapper `fabroGit` installed as `/bin/git` in the Fabro image. It:

- adds `--quiet` to `git clone`, because Fabro's built-in clone path appears to treat any stderr as clone failure, and normal `git clone` writes `Cloning into ...` to stderr on success;
- strips embedded credentials from GitHub HTTPS clone URLs of the form `https://*@github.com/...`, so public clones can still work if Fabro supplies a bad/unusable app token.

This wrapper was verified manually in Docker on the Fabro host with a fake token URL:

```sh
docker run --rm --entrypoint /bin/sh ghcr.io/mattwynne/memba-fabro-dev:latest -lc \
  'rm -rf /tmp/t; git clone https://x-access-token:badtoken@github.com/mattwynne/memba /tmp/t >/tmp/out 2>/tmp/err; rc=$?; echo rc=$rc; echo stderr=; cat /tmp/err; exit $rc'
```

Expected/observed:

```text
rc=0
stderr=
```

## Image rebuild / disk space

On the Fabro host, the Memba checkout is at:

```sh
/storage/repos/memba
```

It was behind and had a dirty `devenv.nix` from earlier attempts. I updated it using HTTPS fetch/reset:

```sh
cd /storage/repos/memba
git fetch https://github.com/mattwynne/memba.git main
git reset --hard FETCH_HEAD
```

Then rebuilt/loaded the image with:

```sh
devenv container run fabro-dev
```

The Fabro host's `/storage` filesystem became full during image work:

```text
/dev/mapper/pve-vm--115--disk--1   98G   97G     0 100% /storage
```

Docker was using about 102GB. I pruned stopped containers and dangling images:

```sh
docker container prune -f
docker image prune -f
```

This reclaimed about 40.5GB and `/storage` dropped to about 20% used.

## What now works

Manual Docker tests on the Fabro host succeed:

```sh
docker run --rm --entrypoint /bin/sh ghcr.io/mattwynne/memba-fabro-dev:latest -lc \
  'rm -rf /tmp/t; git clone --branch main --single-branch --depth 10 --no-tags https://github.com/mattwynne/memba /tmp/t; echo ok'
```

Also the exact clone/link shape succeeds manually:

```sh
docker run --rm --entrypoint /bin/sh ghcr.io/mattwynne/memba-fabro-dev:latest -lc \
  'rm -rf /repos/mattwynne/memba /workspace/memba; mkdir -p /workspace /repos/mattwynne && git -c maintenance.auto=0 -c gc.auto=0 clone --branch main --single-branch --depth 10 --no-tags -- https://github.com/mattwynne/memba /repos/mattwynne/memba && ln -s /repos/mattwynne/memba /workspace/memba && cd /workspace/memba && git rev-parse HEAD'
```

Fabro can now initialize a Docker sandbox when built-in clone is disabled.

A temporary workflow with:

```toml
[run.clone]
enabled = false
```

and a trivial prepare command reached:

- `sandbox.ready`
- `sandbox.initialized`
- `setup.started`
- `setup.command.completed`
- `run.started`

So the original sandbox initialization problem is bypassed by disabling Fabro's built-in clone.

## Current workflow state

`.fabro/workflows/iteration-implementation/workflow.toml` currently has:

```toml
[run]
goal = "Implement a validated iteration plan and leave the codebase passing dev check"
working_dir = "/workspace/memba"

[run.clone]
enabled = false

[[run.prepare.steps]]
command = ["mkdir", "-p", "/repos/mattwynne", "/workspace"]

[[run.prepare.steps]]
command = ["git", "clone", "--branch", "main", "--single-branch", "--depth", "10", "--no-tags", "https://github.com/mattwynne/memba", "/repos/mattwynne/memba"]

[[run.prepare.steps]]
command = ["ln", "-s", "/repos/mattwynne/memba", "/workspace/memba"]

[[run.prepare.steps]]
command = ["git", "-C", "/workspace/memba", "config", "user.email", "fabro@example.invalid"]

[[run.prepare.steps]]
command = ["git", "-C", "/workspace/memba", "config", "user.name", "Fabro"]
```

Explicit Docker resource limits were removed after testing because removing them did not change the failure.

## Current blocker

Fabro prepare step 1 (`mkdir`) succeeds.

Fabro prepare step 2 (`git clone`) is killed almost immediately with exit code `137` and no stderr:

```text
Setup command failed (exit code 137): git clone --branch main --single-branch --depth 10 --no-tags https://github.com/mattwynne/memba /repos/mattwynne/memba
```

Latest failed run at time of writing:

```text
01KSN2NFJRBV1RWHTC0RZJBF0S
https://fabro.home.wynne.family/runs/01KSN2NFJRBV1RWHTC0RZJBF0S
```

Relevant event sequence:

- `sandbox.ready`
- `sandbox.initialized` with `repo_cloned=false`
- `setup.started` with 5 commands
- `setup.command.completed` for `mkdir -p /repos/mattwynne /workspace`
- `setup.command.started` for `git clone ...`
- `setup.failed` exit code `137`, stderr empty
- `run.failed`

This is now different from the earlier built-in clone failure. Built-in clone failed as a Fabro sandbox init error; the current failure is Fabro's setup/prepare exec killing `git clone` with SIGKILL.

## Things tried that did not fix it

- Added `/bin/git` wrapper to quiet successful clone stderr.
- Added stripping of bad embedded GitHub HTTPS credentials.
- Disabled built-in clone and moved checkout into prepare steps.
- Tried prepare as one shell script.
- Split prepare into separate commands.
- Tried with and without `--quiet` on `git clone`.
- Removed explicit Docker CPU/memory resource limits from the workflow.
- Pruned Docker disk usage on the Fabro host.

Manual Docker clone still succeeds, so the problem seems specific to Fabro's setup/prepare exec environment or supervision.

## Possible next debugging steps

1. Use `--preserve-sandbox` with the current prepare failure and inspect whether the failed container remains running or has been killed. Earlier preserve did not help with init failures, but now the sandbox reaches setup, so it may help.
2. Inspect Docker events / container state during the failed prepare step:
   ```sh
   docker events --since ...
   docker inspect <container-id>
   docker logs <container-id>
   ```
3. Compare manual `docker exec` clone against Fabro's setup exec, not just `docker run` clone. Start the image the same way Fabro does, then `docker exec` the clone command.
4. Try making prepare use a bind-mounted existing checkout instead of cloning. Fabro's environment volume schema requires at least an `id`; rough shape to investigate:
   ```toml
   [[environments.memba-dev.volumes]]
   id = "memba-source"
   mount_path = "/workspace/memba"
   subpath = "/storage/repos/memba"
   ```
   This was not completed/validated inside the real workflow.
5. Investigate whether Fabro kills setup commands that write to stderr/stdout unexpectedly, exceed a tiny hidden memory/process limit, or use a command not wrapped in `/bin/sh -lc`.
6. Consider using a custom lightweight checkout mechanism if available tools are added to the image (`curl`, `tar`, etc.). Currently the image did not appear to have `curl`, `wget`, `tar`, `gzip`, `python`, or `python3` available on default PATH.
7. Patch Fabro or run a local/debug server with more verbose logging around setup command process termination.

## Useful commands

Validate workflow:

```sh
fabro validate .fabro/workflows/iteration-implementation/workflow.toml
```

Run workflow:

```sh
fabro run .fabro/workflows/iteration-implementation/workflow.toml -I plan_path=docs/iterations/001-member-message-deliverability/plan.md
```

Run detached:

```sh
fabro run .fabro/workflows/iteration-implementation/workflow.toml -I plan_path=docs/iterations/001-member-message-deliverability/plan.md --detach
```

Inspect run:

```sh
fabro events <run-id>
fabro logs <run-id>
fabro inspect <run-id>
```

Access Fabro host through hub.local without broken agent forwarding:

```sh
cd /Users/matt/git/mattwynne/hub.local
SSH_AUTH_SOCK= PATH="$PWD/bin:$PATH" devenv shell -- console fabro "<command>"
```

Rebuild/load image on Fabro host:

```sh
cd /storage/repos/memba
git fetch https://github.com/mattwynne/memba.git main
git reset --hard FETCH_HEAD
devenv container run fabro-dev
docker tag mattwynne/memba-fabro-dev:latest ghcr.io/mattwynne/memba-fabro-dev:latest
```

Manual clone test on Fabro host:

```sh
docker run --rm --entrypoint /bin/sh ghcr.io/mattwynne/memba-fabro-dev:latest -lc 'rm -rf /tmp/t; git clone --branch main --single-branch --depth 10 --no-tags https://github.com/mattwynne/memba /tmp/t; echo ok'
```

## Follow-up resolution: exit 137 root cause

The prepare `git clone` exit code 137 was caused by the devenv container image entrypoint, not by Git, Docker resource limits, or Fabro killing setup commands directly.

Fabro creates the run container with its own command:

```sh
/bin/bash -lc 'mkdir -p /workspace && sleep infinity'
```

But the image still had devenv's default entrypoint. That entrypoint ran `enterShell`, printed the Memba dev environment banner, then exited. When the entrypoint exited, the container's main process ended and Docker killed the in-flight `docker exec git clone ...`, which surfaced as exit code 137.

Evidence:

- `docker events` showed the clone exec exiting with `exitCode=137`, followed by the run container dying.
- A preserved failed sandbox showed devenv entrypoint output in `docker logs`, including `/env` permission warnings and the Memba environment banner.
- `docker image inspect` showed `Entrypoint=["/nix/store/...-entrypoint"]` before the fix.
- Manual clone tests that used `--entrypoint /bin/sh` bypassed the broken entrypoint and therefore did not reproduce the failure.

Fix applied in `devenv.nix`:

```nix
entrypoint = [];
startupCommand = [ "/bin/bash" "-lc" "sleep infinity" ];
```

After rebuilding/loading/tagging the image on the Fabro host, run `01KSN4WDEWQPKYB9THQ6XCREF6` completed all prepare steps successfully:

- `mkdir -p /repos/mattwynne /workspace`
- `git clone --branch main --single-branch --depth 10 --no-tags https://github.com/mattwynne/memba /repos/mattwynne/memba`
- `ln -s /repos/mattwynne/memba /workspace/memba`
- git config steps

The workflow then started and failed later at `read_plan` because the cloned repository did not contain `docs/iterations/001-member-message-deliverability/plan.md`. That is a separate repository/content issue, not the sandbox clone/prepare exit-137 issue.
