# Fabro and devenv containers

Fabro runs Memba iteration-implementation work inside Docker images built from this project's `devenv.nix` using `devenv container`.

## Published image versions

`.github/workflows/fabro-dev-image.yml` publishes a new tag for each build attempt:
`sha-<full-source-SHA>-run-<GitHub-run-ID>-<attempt>`. Rerunning a build creates a different tag; the pipeline does not publish or promote `latest`. The build and copy commands receive identical version/source/build overrides. Bare containers expose these as `MEMBA_FABRO_IMAGE_VERSION`, `MEMBA_FABRO_IMAGE_SOURCE`, and `MEMBA_FABRO_IMAGE_BUILD` before `devenv shell` resets the runtime environment.

After registry identity and bare `cmp` checks pass, CI uploads the `published-fabro-image-<run-ID>-<attempt>` artifact containing `published-fabro-image.json` (reference, registry digest, source, run ID, attempt) and the registry inspection. **Only select a receipt from a completed, successful image workflow run.** A failed/cancelled run, an incomplete upload, or a current application HEAD with no image build is not a deployment candidate.

Roll out in two stages:

1. Publish the image pipeline/source change and wait for that exact image CI run to succeed. Download its receipt and confirm the source SHA and attempt against the successful run.
2. Copy that successful receipt to `.fabro/fabro-dev-image.json` and set all Memba-owned `.fabro/workflows/*/workflow.toml` Docker image references to its full **version-tagged** reference. Run `python3 .fabro/workflows/scripts/test_fabro_dev_image_pin.py` and `.fabro/workflows/plan-validation/test.sh --static`, validate the exact pin commit with ordinary remote `dev check`, and publish it. Do not synthesize a tag from the current application HEAD. Keep the registry digest as evidence, not as the workflow image syntax (Fabro 0.389 expects a full version-tagged reference).

A fresh Fabro Docker run with this previously uncached tag pulls the published version without relying on a host refresh of `latest`. Verify its bare tools and baked version/source/build identity on `https://fabro.home.wynne.family` before calling rollout complete. The sandbox API exposes the requested tag and container ID, not necessarily a host-local digest: report only the identity actually observed. Existing running/resumed containers are not upgraded or stopped.

Local `devenv container` builds use the non-deployment tag `local`. Manual local builds/copies are not published deployment versions. Use CI for normal publication.

## Operational notes

The following host-maintenance route is historical/manual; normal version-tag rollout does not require SSH or host Docker access.

The production Fabro host is managed from the sibling `hub.local` project.

Useful access pattern from `hub.local`:

```sh
PATH="$PWD/bin:$PATH" devenv shell -- console fabro
```

When Matt is present to approve the SSH host key, direct SSH to the Fabro LXC is also available:

```sh
ssh root@192.168.1.201
# or
ssh root@fabro.home.wynne.family
```

Inside the Fabro LXC, the checked-out Memba repo is currently available at:

```sh
/storage/repos/memba
/Users/matt/git/mattwynne/memba -> /storage/repos/memba
```

To rebuild and load the Fabro dev image on the Fabro host:

```sh
cd /storage/repos/memba
git config --global --add safe.directory /storage/repos/memba
devenv container build fabro-dev
devenv container run fabro-dev
```

`devenv container run` first copies the Nix-built image into the local Docker daemon, then starts it. If all you need is to refresh Docker's local image, it is still the practical command to use.

## Packaging tools for Fabro

Fabro expects common tools such as `git` to be available on `PATH` inside the generated container. The default `devenv` container root supplies a `/bin` with shell/coreutils, but packages in the top-level `packages` list are not automatically linked into `/bin`.

In this project, we make bare-shell workflow tools available to Fabro by adding an explicit container layer. This includes `nix`, which runtime `devenv shell` realization needs, `python3`, which iteration finalization scripts invoke directly, and `diffutils`, which supplies `cmp` for before/after evidence comparisons. These tools must work outside `bin/dev`'s `devenv shell` boundary.

`/bin/git` in the Fabro image is a wrapper that adds two sandbox-init accommodations before delegating to the real Git binary:

- it adds `--quiet` to `git clone`, because Fabro currently treats any stderr from the pre-shell clone step as a clone failure, while ordinary `git clone` writes `Cloning into ...` to stderr even when it succeeds;
- it strips embedded credentials from GitHub HTTPS clone URLs, allowing public repository clones to succeed even if Fabro's GitHub App token path is unavailable or misconfigured.


```nix
let
  fabroGit = pkgs.writeShellScriptBin "git" ''
    # wrapper elided here; it inserts --quiet for clone
    exec ${pkgs.git}/bin/git "$@"
  '';

  fabroWritableDirs = pkgs.runCommand "memba-fabro-dev-writable-dirs" { } ''
    mkdir -p $out/repos $out/workspace
  '';
in
{
  containers."fabro-dev" = {
    # ...
    copyToRoot = [];
    layers = [
      {
        copyToRoot = [
          (pkgs.buildEnv {
            name = "memba-fabro-dev-root";
            paths = [ fabroGit ];
            pathsToLink = [ "/bin" ];
          })
          fabroWritableDirs
        ];
        perms = [
          {
            path = fabroWritableDirs;
            regex = "/repos";
            mode = "0777";
            uid = 1000;
            gid = 1000;
            uname = "user";
            gname = "user";
          }
          {
            path = fabroWritableDirs;
            regex = "/workspace";
            mode = "0777";
            uid = 1000;
            gid = 1000;
            uname = "user";
            gname = "user";
          }
        ];
      }
    ];
  };
}
```

This produces `/bin/git` in the final image, so it is found by the default container `PATH`, and avoids benign clone progress on stderr during Fabro sandbox initialization.

Fabro supplies the run container command itself. The default devenv container entrypoint runs `enterShell` and then exits, which terminates Fabro's run container and kills in-flight `docker exec` commands with exit code 137. Override the generated entrypoint, but use `tini` as PID 1 so the long-lived run container reaps orphaned child processes from repeated `docker exec` commands and browser acceptance-test runs:

```nix
containers."fabro-dev" = {
  entrypoint = [ "/bin/tini" "-g" "--" ];
  startupCommand = [ "/bin/bash" "-lc" "sleep infinity" ];
};
```

Fabro's Docker sandbox also needs to create `/repos/{owner}/{repo}` and `/workspace/{repo}`. The current Docker sandbox implementation clones into `/repos/{owner}/{repo}` and symlinks `/workspace/{repo}` to that checkout. Custom images whose runtime user is non-root must therefore provide writable `/repos` and `/workspace` directories. Nix store paths are read-only, so set the directory modes with the layer `perms` option rather than relying on `chmod` in the derivation. Also set the image `workingDir` to `/workspace`, not `/workspace/<repo>`, otherwise the image may contain a pre-existing root-owned `/workspace/<repo>` directory that blocks Fabro from creating the symlink.

Git clone over HTTPS also needs CA certificates before `devenv`'s shell startup has run. Set both `SSL_CERT_FILE` and `NIX_SSL_CERT_FILE` in `env`:

```nix
env = {
  SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
};
```

A subtle trap: putting the same `pkgs.buildEnv` directly in `containers."fabro-dev".copyToRoot` does not work the way it first appears. Devenv treats top-level `copyToRoot` as project/home content and copies it under `/env`; it does not overlay those paths onto `/`. For root-level paths such as `/bin/git`, use `containers.<name>.layers[].copyToRoot`.

## Verification

For manual host verification, set `IMAGE` to the full reference from a successful CI receipt (never `latest` or an arbitrary source SHA), then run:

```sh
docker run --rm --entrypoint /bin/sh "$IMAGE" -lc 'command -v git && git --version && command -v nix && nix --version && command -v python3 && python3 --version && command -v cmp && cmp --version && test -r "$SSL_CERT_FILE" && mkdir -p /repos/test /workspace/test'
```

Expected shape:

```sh
/bin/git
git version ...
/bin/nix
nix ...
/bin/python3
Python ...
```
