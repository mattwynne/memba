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

## Packaging tools for Fabro

Fabro expects common tools such as `git` to be available on `PATH` inside the generated container. The default `devenv` container root supplies a `/bin` with shell/coreutils, but packages in the top-level `packages` list are not automatically linked into `/bin`.

In this project, we make Git available to Fabro by adding an explicit container layer:

```nix
containers."fabro-dev" = {
  # ...
  copyToRoot = [];
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
};
```

This produces `/bin/git` in the final image, so it is found by the default container `PATH`.

A subtle trap: putting the same `pkgs.buildEnv` directly in `containers."fabro-dev".copyToRoot` does not work the way it first appears. Devenv treats top-level `copyToRoot` as project/home content and copies it under `/env`; it does not overlay those paths onto `/`. For root-level paths such as `/bin/git`, use `containers.<name>.layers[].copyToRoot`.

## Verification

After rebuilding/loading the image on Fabro, verify with:

```sh
docker run --rm --entrypoint /bin/sh mattwynne/memba-fabro-dev:latest -lc 'command -v git && git --version'
```

Expected shape:

```sh
/bin/git
git version ...
```
