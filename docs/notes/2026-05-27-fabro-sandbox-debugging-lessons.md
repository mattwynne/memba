# What It Took to Get Fabro Working Remotely with `devenv.nix`

Date: 2026-05-27

This is the consolidated history of the work to get Memba's Fabro iteration workflow running on a remote Fabro server, using a Docker sandbox image produced by this repository's `devenv.nix`.

Sources checked for this write-up:

- Git history in this repo, especially the Fabro/devenv commits from `f237488` through `57a1956`.
- Earlier notes in `docs/retros/2026-05-27.md` and `docs/retros/2026-05-27-fabro-sandbox-followup.md`.
- `docs/reference/fabro-devenv.md`.
- Holocron sessions for Memba and hub.local on 2026-05-27, especially:
  - `pi:019e6812` — get dev environment working on Fabro server.
  - `pi:019e68c8` / `pi:019e6a2e` / `pi:019e6a54` — Fabro sandbox image and workflow debugging.
  - `pi:019e6af5` — Postgres, process-compose, and devenv shell debugging.

## Executive summary

The work was not one bug. It was a chain of environment-boundary bugs.

We had to make three layers agree with each other:

1. The remote Fabro host: an LXC/container managed from `hub.local`, with enough disk and Docker storage to run Fabro and nested Docker sandboxes.
2. The Fabro sandbox image: a `devenv container` image that Fabro can start, clone into, and execute inside before any friendly `devenv shell` setup has run.
3. The Memba developer command layer: `bin/dev`, `devenv shell`, process-compose, Postgres, Mix, Hex, and writable cache/home directories.

The final shape is:

- The Fabro host stores Docker/containerd data under `/storage`, backed by a 100G local-lvm volume.
- The Memba `fabro-dev` image provides the tools Fabro needs on the default container `PATH`.
- The image has writable `/workspace` and `/repos` directories for Fabro's clone/link convention.
- The image disables the default devenv container entrypoint, because Fabro supplies its own long-running command.
- The workflow disables Fabro's built-in clone path and prepares the checkout explicitly.
- The sandbox `devenv` wrapper resets baked-in `/env` state and gives Mix/Hex/NIF builds writable locations under `/tmp`.
- `bin/dev` always re-enters a clean `devenv shell` once, starts Postgres idempotently, and verifies readiness with `pg_isready`.

## Stage 0: the remote Fabro host had to be fit for Docker sandboxes

The Fabro server itself lives in the `hub.local` infrastructure project, not in this repository.

The relevant host is the `fabro` LXC/container. Early inspection showed it had only modest resources:

```text
memory: 2048M dedicated, 1024M swap
/root disk: initially small
/storage: mounted from /home/fabro/storage
```

Running Fabro alone was fine. Running Fabro plus Docker plus Nix-built images was not.

We installed/provisioned the basics on the Fabro host:

- Docker inside the LXC.
- CA certificates, curl, openssl.
- Nix/devenv support where needed.
- Fabro's own service and config under `/root/.config/fabro` and `/storage`.

The important storage fix was to move Fabro storage and Docker runtime storage onto local-lvm:

```text
rootfs:  local-lvm:vm-115-disk-0,size=30G
/storage: local-lvm:vm-115-disk-1,size=100G
DockerRootDir=/storage/docker
containerd root=/storage/containerd
```

That change was committed in `hub.local` as:

```text
e662ff9 Move Fabro storage to local-lvm
```

We also cleaned up old Docker/containerd state after moving roots. Afterward the server had plenty of space for image pulls/builds:

```text
/:        30G total, about 18G free
/storage: 98G total, about 91G free
```

`fabro doctor --server https://fabro.home.wynne.family` then passed the important checks:

- server location reachable;
- LLM providers configured;
- GitHub token configured;
- crypto/auth material valid;
- storage directory `/storage` healthy.

Remaining warnings were not blockers for local Docker sandbox work: CLI/server version parity, missing Daytona API key, and missing Brave Search key.

## Stage 1: create a Fabro Docker environment from `devenv.nix`

Commit:

```text
f237488 Build Fabro dev image with devenv
```

This introduced a Docker environment in `.fabro/workflows/iteration-implementation/workflow.toml`:

```toml
[run.environment]
id = "memba-dev"

[environments.memba-dev]
provider = "docker"

[environments.memba-dev.image]
ref = "ghcr.io/mattwynne/memba-fabro-dev:latest"
```

And it added the first `containers."fabro-dev"` block to `devenv.nix`:

```nix
containers."fabro-dev" = {
  name = "mattwynne/memba-fabro-dev";
  registry = "docker://ghcr.io/";
  version = "latest";
  copyToRoot = [];
  workingDir = "/workspace/memba";
};
```

This was only the beginning. A raw `devenv container` image did not yet have the filesystem shape or boot behavior Fabro's Docker sandbox expected.

## Stage 2: top-level `packages` were not enough

Commits:

```text
c1a148f Add git to devenv packages
d88fa11 Package git in Fabro devenv image
```

The first failure was simple: Fabro needed `git` during sandbox setup, before a devenv shell had been entered.

Adding `git` to top-level `packages` made it available inside a normal devenv shell, but not necessarily on the default `/bin` path Fabro uses during sandbox initialization.

The fix was to add an explicit image layer:

```nix
layers = [
  {
    copyToRoot = [
      (pkgs.buildEnv {
        name = "memba-fabro-dev-root";
        paths = [ pkgs.git ];
        pathsToLink = [ "/bin" ];
      })
    ];
  }
];
```

Lesson: if Fabro needs a tool before `devenv shell` runs, put it on the image's default execution path, not just in the devenv profile.

## Stage 3: Fabro needs writable `/repos` and `/workspace`

Commit:

```text
727e6b4 Make Fabro sandbox workspace writable
```

Fabro's Docker sandbox clone convention is roughly:

```sh
mkdir -p /workspace /repos/<owner> && \
  git clone --branch <branch> --single-branch --depth 10 --no-tags -- \
    <clone-url> /repos/<owner>/<repo> && \
  ln -s /repos/<owner>/<repo> /workspace/<repo>
```

Our image runs as a non-root runtime user. That user could not create `/repos` or `/workspace` unless we prepared those paths.

One failed run showed:

```text
mkdir: cannot create directory '/repos': Permission denied
```

The fix was a Nix derivation that creates the directories plus layer `perms` entries that make them writable by UID/GID 1000:

```nix
fabroWritableDirs = pkgs.runCommand "memba-fabro-dev-writable-dirs" { } ''
  mkdir -p $out/repos $out/workspace
'';
```

Then add `fabroWritableDirs` to the layer and set permissions for `/repos` and `/workspace`.

Lesson: Nix store paths are read-only. `chmod` inside the derivation is not enough for root-level writable runtime paths; use the container layer `perms` option.

## Stage 4: HTTPS clone needed CA certificates before shell startup

Commit:

```text
74999b9 Complete Fabro Docker sandbox image requirements
```

A later clone failure was misleading. Fabro surfaced only:

```text
Failed to clone repo into Docker sandbox: Cloning into '/repos/mattwynne/memba'...
```

Manual reproduction inside the image showed the real error:

```text
fatal: unable to access 'https://github.com/mattwynne/memba/': SSL certificate OpenSSL verify result: unable to get local issuer certificate (20)
```

The fix was to set certificate paths in `devenv.nix`:

```nix
env = {
  SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
};
```

The same commit changed the container `workingDir` from `/workspace/memba` to `/workspace`. That mattered because baking `/workspace/memba` into the image could leave a pre-existing, non-writable path where Fabro wanted to create a symlink.

Lesson: Fabro's clone/link path owns `/workspace/<repo>`. Do not bake that repo path into the image.

## Stage 5: Fabro's built-in clone path was hard to observe

Commits:

```text
610a6ae Quiet Fabro sandbox git clone
59d388c Make Fabro git clone tolerate token URLs
```

We discovered two more clone-path problems.

First, ordinary `git clone` writes progress such as `Cloning into ...` to stderr even when it succeeds. The observed Fabro behavior suggested its built-in clone path could treat any clone stderr as failure, or at least report only the first stderr line.

Second, Fabro could supply GitHub HTTPS URLs with embedded credentials. If that token path was broken, a public clone could still work if we stripped the credentials.

We wrapped `/bin/git` in the image:

- add `--quiet` to `git clone` if not already present;
- rewrite `https://*@github.com/...` to `https://github.com/...` for clone commands.

Manual test on the Fabro host with a fake token URL succeeded with empty stderr:

```sh
docker run --rm --entrypoint /bin/sh ghcr.io/mattwynne/memba-fabro-dev:latest -lc \
  'rm -rf /tmp/t; git clone https://x-access-token:badtoken@github.com/mattwynne/memba /tmp/t >/tmp/out 2>/tmp/err; rc=$?; echo rc=$rc; echo stderr=; cat /tmp/err; exit $rc'
```

Lesson: quiet, deterministic sandbox setup output matters. Normal CLI progress can be poison when an orchestrator treats stderr as failure signal.

## Stage 6: disable built-in clone and prepare the checkout explicitly

During this period we tried several workflow shapes:

- Fabro built-in clone enabled.
- Built-in clone disabled with a single shell prepare script.
- Built-in clone disabled with split prepare steps.
- Cloning into `/repos/mattwynne/memba` then symlinking `/workspace/memba`.
- Later, cloning directly into `/workspace` to match `working_dir = "/workspace/memba"` behavior in the workflow adjustments.

The useful breakthrough was disabling built-in clone:

```toml
[run.clone]
enabled = false
```

and moving checkout into `[[run.prepare.steps]]`.

That changed the failure mode from opaque sandbox initialization failure to observable setup-command failure. Once the sandbox reached `sandbox.ready`, `sandbox.initialized`, and `setup.started`, `--preserve-sandbox`, Docker events, Docker logs, and `docker inspect` became useful.

Lesson: when an orchestrator hides too much during built-in setup, move setup into explicit workflow steps so it becomes observable.

## Stage 7: exit 137 was the devenv container entrypoint

Commit:

```text
51efb68 Fix Fabro sandbox container entrypoint
```

A prepare `git clone` step was being killed almost immediately:

```text
Setup command failed (exit code 137): git clone ...
```

This looked like an OOM kill, a Docker resource limit, a Git problem, or Fabro killing the process. It was none of those.

Root cause: the image still had devenv's default generated entrypoint. Fabro creates the run container with its own command, roughly:

```sh
/bin/bash -lc 'mkdir -p /workspace && sleep infinity'
```

But Docker runs the image entrypoint first. Devenv's entrypoint ran `enterShell`, printed the Memba banner, and exited. When the container's main process exited, Docker killed the in-flight `docker exec git clone ...`, surfacing as exit code 137.

Evidence from the prior session:

- `docker events` showed the clone exec exiting with `exitCode=137`, followed by the run container dying.
- A preserved failed sandbox had devenv entrypoint output in `docker logs`, including `/env` permission warnings and the Memba environment banner.
- `docker image inspect` showed `Entrypoint=["/nix/store/...-entrypoint"]` before the fix.
- Manual clone tests used `--entrypoint /bin/sh`, which bypassed the problem and explained why manual Docker runs had succeeded.

The fix:

```nix
containers."fabro-dev" = {
  entrypoint = [];
  startupCommand = [ "/bin/bash" "-lc" "sleep infinity" ];
};
```

After rebuilding and loading the image on the Fabro host, the prepare steps completed.

Lesson: when an orchestrator supplies the container command, a generated image entrypoint can silently override or wrap the lifecycle in ways that kill later `docker exec` commands.

## Stage 8: the cloned repo did not contain the plan until planning artifacts were pushed

After the sandbox and prepare clone worked, the workflow failed at `read_plan` because the remote clone did not contain:

```text
docs/iterations/001-member-message-deliverability/plan.md
```

That was a separate content/visibility issue. The iteration planning artifacts had to be committed and pushed before a remote Fabro sandbox could read them.

Relevant commits around this part of the project history include:

```text
656a66d Require pushing planning artifacts before Fabro validation
8ff29cb Publish ready plans from validation workflow
af59c49 Mark deliverability iteration Fabro ready
```

Lesson: remote sandboxes see committed/pushed repository state, not the developer's local working tree.

## Stage 9: sandbox preflight needed real tools, not just the image

Commit:

```text
7dc0d02 Fix Fabro workflow sandbox tools
```

Once the workflow could read the plan, it needed to prove the sandbox was actually usable before letting an implementation agent start coding.

The preflight checked for:

- `devenv`
- `git`
- executable `bin/dev`
- `argc`
- `elixir`
- `mix`
- `node`
- `npm`

This commit also adjusted the image layer to include more tools on `/bin`, such as:

- `argc`
- `bashInteractive`
- `coreutils-full`
- `devenv`
- `elixir`
- `findutils`
- `gnugrep`
- `gnused`
- `nodejs_22`

The `read_plan` script was also changed to avoid relying on `sed`; it reads up to 320 lines with shell built-ins instead.

Lesson: every command used before `devenv shell` must be available in the image's bare execution environment.

## Stage 10: runtime `devenv` inherited stale `/env` and Postgres variables

Commit:

```text
e10fe25 Reset devenv environment in Fabro sandbox
```

The generated devenv image bakes environment variables that point at `/env`. But Fabro clones the repo into `/workspace`. Runtime commands like `devenv shell ...` must evaluate the checked-out repo, not the baked `/env` state.

The fix was a high-priority wrapper for `devenv` installed into `/bin`:

```sh
unset DEVENV_DOTFILE DEVENV_PROFILE DEVENV_ROOT DEVENV_STATE DEVENV_TASKS DEVENV_TASK_FILE
unset PGDATA PGHOST PGPORT
export HOME="${HOME:-/tmp/home}"
export DEVENV_HOME="${DEVENV_HOME:-/tmp/devenv-home}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/cache}"
mkdir -p "$HOME" "$DEVENV_HOME" "$XDG_CACHE_HOME"
exec ${pkgs.devenv}/bin/devenv "$@"
```

This was the first version of the fix that later explained the Postgres socket mismatch too.

Lesson: a Nix/devenv image is both a build artifact and a runtime environment. The baked environment can be stale or actively wrong once Fabro clones a fresh repo elsewhere.

## Stage 11: Mix, Hex, and Erlang needed certificates, locale, and writable paths

Commits:

```text
3c415d9 Provide Mix certs in Fabro sandbox
57a1956 Use writable home in Fabro devenv shell
```

After the sandbox got far enough to run Mix, new failures appeared. These were not app failures; they were runtime environment gaps.

Mix/Hex needed CA certificates:

```nix
HEX_CACERTS_PATH = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
```

Erlang/Elixir needed sane Unicode/locale settings:

```nix
ELIXIR_ERL_OPTIONS = "+fnu";
LANG = "C.UTF-8";
LC_ALL = "C.UTF-8";
```

Mix, Hex, and compiled dependencies needed a writable home/cache. One later failure from `lazy_html` made this explicit:

```text
could not make directory (with -p) "/env/.cache/elixir_make": no such file or directory
```

The final environment forced writable paths under `/tmp`:

```nix
HOME = "/tmp/home";
MIX_HOME = "/tmp/home/.mix";
HEX_HOME = "/tmp/home/.hex";
```

and the wrapper ensured cache directories existed:

```sh
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/cache}"
mkdir -p "$HOME" "$DEVENV_HOME" "$XDG_CACHE_HOME"
```

Lesson: a sandbox is not a normal developer laptop. If a compiler or package manager might write, give it an explicit writable place.

## Stage 12: `bin/dev` skipped the real devenv boundary

The next loud symptom was Postgres:

```text
Postgrex.Protocol failed to connect:
tcp connect (/tmp/devenv/postgres/.s.PGSQL.5432): no such file or directory
```

At first this looked like Postgres had not started. But `devenv up` had run, and process-compose had been involved. The real clue was the socket path.

`bin/dev` originally did this:

```sh
if ! command -v argc >/dev/null 2>&1; then
  exec devenv shell -- "$0" "$@"
fi
```

In the Fabro image, `argc` was already on `PATH`, so `bin/dev` skipped `devenv shell`. That left the process in a half-devenv state: enough tools were present to continue, but stale variables such as `PGHOST=/tmp/devenv/postgres` could survive from the baked image.

The result was incoherent:

- `dev up` started Postgres through one environment.
- Mix attempted to connect through another environment's stale socket path.

The fix was to make `bin/dev` always re-enter a clean devenv shell once, while unsetting stale variables before re-entry:

```sh
if [ "${MEMBA_DEVENV_SHELL:-}" != "1" ]; then
  exec env \
    -u DEVENV_DOTFILE \
    -u DEVENV_PROFILE \
    -u DEVENV_ROOT \
    -u DEVENV_STATE \
    -u DEVENV_TASKS \
    -u DEVENV_TASK_FILE \
    -u PGDATA \
    -u PGHOST \
    -u PGPORT \
    MEMBA_DEVENV_SHELL=1 \
    devenv shell -- "$0" "$@"
fi
```

Lesson: `devenv shell` is not just a convenience. In this setup it is the boundary that makes runtime paths, services, and tool configuration coherent.

## Stage 13: process-compose commands had to be idempotent

A later run hit:

```text
Processes already running with PID ...
```

The app had not failed. The lifecycle contract had failed. A setup command had started a process manager; a later command tried to start it again.

The fix was to make developer service commands tolerate existing state:

- `dev up` checks whether a process manager is already running.
- If it is, it starts or ensures Postgres rather than failing.
- `dev down` is best-effort.
- Cleanup traps do not turn a successful test run into a failure.

`dev up` also now waits for process-compose and then checks the actual service:

```sh
devenv processes wait --timeout 120
pg_isready -h "$PGHOST" -p "$PGPORT" >/dev/null
```

Lesson: CI and agent sandboxes often re-run setup paths. Developer commands should be idempotent where possible.

## Stage 14: preflight had to prove Postgres, not just binaries

The original preflight proved only that tools existed. That was necessary but insufficient.

The workflow depended on a reachable Postgres socket from the same command path that Mix would use later. So preflight was tightened to include `pg_isready` and a real `dev up`:

```sh
devenv shell -- bash -lc 'command -v pg_isready' >/dev/null
PATH="$PWD/bin:$PATH" dev --help >/dev/null
trap 'PATH="$PWD/bin:$PATH" dev down >/dev/null 2>&1 || true' EXIT
PATH="$PWD/bin:$PATH" dev up >/dev/null
```

Lesson: a preflight should prove the dependency contract. Do not ask only "is Postgres installed?" Ask "can this command path reach the Postgres socket it will use later?"

## Stage 15: `dev check` needed to own its service dependencies

`dev ci` had started services, but `dev check` originally just ran Mix precommit. The project guideline says agents should finish with `dev check`, so `dev check` itself needed to start required services.

The command layer was refactored:

- `precommit()` runs `mix precommit` in `web`.
- `dev ci` starts services then runs `precommit`.
- `dev check` also starts services then runs `precommit`.
- Both use cleanup traps.

Validation then passed locally:

```sh
fabro validate .fabro/workflows/iteration-implementation/workflow.fabro
PATH="$PWD/bin:$PATH" dev check
```

Lesson: the standard quality gate should be self-contained. If it needs a database, it should start and wait for the database.

## Stage 16: there were unrelated but confusing sandbox/cache failures

Not every failure belonged to the same root cause.

One run failed earlier during setup with a Nix store error:

```text
error: path '/nix/store/...-build.kaem' is not valid
```

A retry passed that phase. That suggested a sandbox/cache issue, not the same Postgres/environment bug.

Another failure involved `lazy_html` / `elixir_make` writing into `/env`, which led to the writable home/cache fixes described above.

Lesson: keep failures separated. Similar timing does not mean same cause.

## Stage 17: file ownership and executable mode can break the fix itself

One sandbox debugging surprise: a copied or edited `bin/dev` became root-owned and non-executable in the sandbox. Attempts to overwrite or `chmod` it failed even though the directory looked writable.

The working move was to unlink the file and recreate it as the sandbox user.

Lesson: content, mode, and ownership are separate facts. A patch can change file content while still leaving the workflow unable to execute the file.

## Final state of the important fixes

The complete set of relevant Memba commits, in historical order, is:

```text
f237488 Build Fabro dev image with devenv
b95b69e Configure devenv container inputs
c1a148f Add git to devenv packages
d88fa11 Package git in Fabro devenv image
727e6b4 Make Fabro sandbox workspace writable
74999b9 Complete Fabro Docker sandbox image requirements
610a6ae Quiet Fabro sandbox git clone
59d388c Make Fabro git clone tolerate token URLs
51efb68 Fix Fabro sandbox container entrypoint
7dc0d02 Fix Fabro workflow sandbox tools
e10fe25 Reset devenv environment in Fabro sandbox
3c415d9 Provide Mix certs in Fabro sandbox
57a1956 Use writable home in Fabro devenv shell
```

The important non-Memba host commit was:

```text
e662ff9 Move Fabro storage to local-lvm
```

The final operating model is:

1. Build/load the image on the Fabro host from `/storage/repos/memba`.
2. Ensure Docker uses `/storage/docker` and containerd uses `/storage/containerd`.
3. Use the `fabro-dev` image with:
   - tools available under `/bin`;
   - CA certificates configured;
   - writable `/repos` and `/workspace`;
   - no conflicting default entrypoint;
   - writable home/cache paths.
4. Run the workflow with committed and pushed iteration plans.
5. Let preflight prove the real sandbox contract, including Postgres readiness.
6. Let `dev check` own its service lifecycle.

## The main lessons

### 1. Remote agent workflows are product code

The workflow has users, contracts, and failure modes. Treat it like production code.

### 2. Debug by boundary, not by symptom

Most failures were boundary mismatches:

- Fabro versus Docker entrypoint.
- Docker image versus runtime clone path.
- Nix store versus writable runtime filesystem.
- Devenv-baked `/env` state versus Fabro's `/workspace` checkout.
- Process-compose service state versus repeated CI commands.
- Postgres socket path versus Mix's inherited environment.

### 3. Make hidden setup observable

Disabling built-in clone and moving checkout into prepare steps made the problem debuggable.

### 4. `devenv shell` is a hard environment boundary

Skipping it because one tool happens to be on `PATH` creates a half-working environment that fails later in misleading ways.

### 5. Preflight the real dependency

A list of binaries is not enough. The workflow depends on a reachable database, writable caches, a usable checkout, certificates, and an idempotent process manager.

### 6. Give sandboxes explicit writable paths

Do not rely on `$HOME`, `/env`, or generated image defaults being writable. Set `HOME`, `MIX_HOME`, `HEX_HOME`, and `XDG_CACHE_HOME` deliberately.

### 7. Watch for misleading successful manual reproductions

Manual Docker tests initially used `--entrypoint /bin/sh`, bypassing the broken image entrypoint. That made them pass while Fabro still failed. The reproduction must match the orchestrator's lifecycle.

### 8. Separate unrelated failures

Nix cache/store glitches, clone output problems, entrypoint exit 137, Postgres socket mismatch, and `lazy_html` cache writes were different failures. Treating them as one would have led to random patches.

## Useful commands kept from the sessions

Access the Fabro host via `hub.local`:

```sh
cd /Users/matt/git/mattwynne/hub.local
SSH_AUTH_SOCK= PATH="$PWD/bin:$PATH" devenv shell -- console fabro "<command>"
```

Rebuild/load the Memba image on the Fabro host:

```sh
cd /storage/repos/memba
git fetch https://github.com/mattwynne/memba.git main
git reset --hard FETCH_HEAD
devenv container run fabro-dev
docker tag mattwynne/memba-fabro-dev:latest ghcr.io/mattwynne/memba-fabro-dev:latest
```

Verify image basics:

```sh
docker run --rm --entrypoint /bin/sh ghcr.io/mattwynne/memba-fabro-dev:latest -lc \
  'command -v git && git --version && test -r "$SSL_CERT_FILE" && mkdir -p /repos/test /workspace/test'
```

Run the workflow:

```sh
fabro run .fabro/workflows/iteration-implementation/workflow.toml \
  -I plan_path=docs/iterations/001-member-message-deliverability/plan.md
```

Inspect runs:

```sh
fabro events <run-id>
fabro logs <run-id>
fabro inspect <run-id>
```

Validate locally:

```sh
fabro validate .fabro/workflows/iteration-implementation/workflow.fabro
PATH="$PWD/bin:$PATH" dev check
```
