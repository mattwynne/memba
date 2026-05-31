# Fabro and devenv containers

Fabro runs Memba iteration-implementation work inside Docker images built from this project's `devenv.nix` using `devenv container`.

## Operational notes

The production Fabro host is managed from the sibling `hub.local` project.

Useful access pattern from `hub.local`:

```sh
PATH="$PWD/bin:$PATH" devenv shell -- console fabro
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

CI publishes `ghcr.io/mattwynne/memba-fabro-dev:latest` and a commit-tagged image for every push to `main`. Delivery helpers wait for the commit tag to appear in GHCR, generate a temporary workflow config with that immutable image reference, and run Fabro with it instead of relying on Docker to refresh a cached `:latest` tag.

## Packaging tools for Fabro

Fabro expects common tools such as `git` to be available on `PATH` inside the generated container. The default `devenv` container root supplies a `/bin` with shell/coreutils, but packages in the top-level `packages` list are not automatically linked into `/bin`.

In this project, we make bare-shell workflow tools available to Fabro by adding an explicit container layer. This includes `python3`, which iteration finalization scripts invoke directly, outside `bin/dev`'s `devenv shell` boundary.

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

Fabro supplies the run container command itself. The default devenv container entrypoint runs `enterShell` and then exits, which terminates Fabro's run container and kills in-flight `docker exec` commands with exit code 137. Override the image entrypoint and provide a harmless default command:

```nix
containers."fabro-dev" = {
  entrypoint = [];
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

After rebuilding/loading the image on Fabro, verify with:

```sh
docker run --rm --entrypoint /bin/sh mattwynne/memba-fabro-dev:latest -lc 'command -v git && git --version && command -v python3 && python3 --version && test -r "$SSL_CERT_FILE" && mkdir -p /repos/test /workspace/test'
```

Expected shape:

```sh
/bin/git
git version ...
/bin/python3
Python ...
```
