{ pkgs, ... }:

let
  fabroGit = pkgs.writeShellScriptBin "git" ''
    set -euo pipefail

    args=()
    is_clone=0
    while [ "$#" -gt 0 ]; do
      case "$1" in
        clone)
          is_clone=1
          args+=("$1")
          shift

          has_quiet=0
          for arg in "$@"; do
            case "$arg" in
              -q|--quiet) has_quiet=1 ;;
            esac
          done
          if [ "$has_quiet" -eq 0 ]; then
            args+=("--quiet")
          fi
          break
          ;;
        -c|--config-env)
          args+=("$1")
          shift
          if [ "$#" -gt 0 ]; then
            args+=("$1")
            shift
          fi
          ;;
        *)
          args+=("$1")
          shift
          ;;
      esac
    done

    if [ "$is_clone" -eq 1 ]; then
      for arg in "$@"; do
        case "$arg" in
          https://*@github.com/*)
            args+=("https://github.com/''${arg#*@github.com/}")
            ;;
          *)
            args+=("$arg")
            ;;
        esac
      done
      exec ${pkgs.git}/bin/git "''${args[@]}"
    fi

    exec ${pkgs.git}/bin/git "''${args[@]}" "$@"
  '';

  fabroDevenv = pkgs.writeShellScriptBin "devenv" ''
    set -euo pipefail

    # Devenv's generated container image bakes DEVENV_* variables pointing at
    # /env, but Fabro clones the repository into /workspace. Reset those values
    # so runtime `devenv shell ...` commands evaluate the checked-out repo, and
    # give devenv a writable home/cache in the otherwise minimal container.
    unset DEVENV_DOTFILE DEVENV_PROFILE DEVENV_ROOT DEVENV_STATE DEVENV_TASKS DEVENV_TASK_FILE
    unset PGDATA PGHOST PGPORT
    export HOME="''${HOME:-/tmp/home}"
    if [ "$HOME" = /env ] || [ ! -d "$HOME" ] || [ ! -w "$HOME" ]; then
      export HOME=/tmp/home
    fi
    export DEVENV_HOME="''${DEVENV_HOME:-/tmp/devenv-home}"
    export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-/tmp/cache}"
    if [ -z "''${HEX_CACERTS_PATH:-}" ]; then
      if [ -n "''${SSL_CERT_FILE:-}" ]; then
        export HEX_CACERTS_PATH="$SSL_CERT_FILE"
      elif [ -n "''${NIX_SSL_CERT_FILE:-}" ]; then
        export HEX_CACERTS_PATH="$NIX_SSL_CERT_FILE"
      fi
    fi
    export ELIXIR_ERL_OPTIONS="''${ELIXIR_ERL_OPTIONS:-+fnu}"
    export LANG="''${LANG:-C.UTF-8}"
    export LC_ALL="''${LC_ALL:-C.UTF-8}"
    mkdir -p "$HOME" "$DEVENV_HOME" "$XDG_CACHE_HOME"

    exec ${pkgs.devenv}/bin/devenv "$@"
  '';

  fabroWritableDirs = pkgs.runCommand "memba-fabro-dev-writable-dirs" { } ''
    mkdir -p $out/repos $out/workspace
  '';
in
{
  packages = with pkgs; [
    adrgen
    argc
    devenv
    git
    nodejs_22
    tailwindcss_4
    fontconfig
    esbuild
    flyctl
  ];

  languages.elixir.enable = true;

  env = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    HEX_CACERTS_PATH = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    ELIXIR_ERL_OPTIONS = "+fnu";
    LANG = "C.UTF-8";
    LC_ALL = "C.UTF-8";
    HOME = "/tmp/home";
    MIX_HOME = "/tmp/home/.mix";
    HEX_HOME = "/tmp/home/.hex";
    FONTCONFIG_PATH = "${pkgs.fontconfig.out}/etc/fonts";
    FONTCONFIG_FILE = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
    MIX_TAILWIND_PATH = "${pkgs.tailwindcss_4}/bin/tailwindcss";
    MIX_ESBUILD_PATH = "${pkgs.esbuild}/bin/esbuild";
  };

  scripts.mix.exec = ''
    cd web
    exec ${pkgs.elixir}/bin/mix "$@"
  '';

  scripts.acceptance-test.exec = ''
    cd acceptance-tests
    exec npm test -- "$@"
  '';

  services.postgres = {
    enable = true;
    initialDatabases = [{ name = "memba_dev"; }];
  };

  containers."fabro-dev" = {
    name = "mattwynne/memba-fabro-dev";
    registry = "docker://ghcr.io/";
    version = "latest";
    # Fabro supplies the container command itself. The default devenv entrypoint
    # runs enterShell and then exits, which terminates Fabro's run container and
    # kills in-flight docker exec commands such as git clone with exit 137.
    entrypoint = [];
    startupCommand = [ "/bin/bash" "-lc" "sleep infinity" ];
    copyToRoot = [];
    layers = [
      {
        copyToRoot = [
          (pkgs.buildEnv {
            name = "memba-fabro-dev-root";
            paths = with pkgs; [
              argc
              bashInteractive
              coreutils-full
              devenv
              elixir
              findutils
              gnugrep
              gnused
              nodejs_22
    tailwindcss_4
    fontconfig
    esbuild
    flyctl
              which
              (hiPrio fabroDevenv)
              (hiPrio fabroGit)
            ];
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
    workingDir = "/workspace";
  };

  enterShell = ''
    if [ "$HOME" = "/env" ] || [ ! -d "$HOME" ] || [ ! -w "$HOME" ]; then
      export HOME=/tmp/home
    fi
    export MIX_HOME="''${MIX_HOME:-$HOME/.mix}"
    export HEX_HOME="''${HEX_HOME:-$HOME/.hex}"
    export HEX_CACERTS_PATH="''${HEX_CACERTS_PATH:-''${SSL_CERT_FILE:-''${NIX_SSL_CERT_FILE:-}}}"
    export ELIXIR_ERL_OPTIONS="''${ELIXIR_ERL_OPTIONS:-+fnu}"
    mkdir -p "$HOME" "$MIX_HOME" "$HEX_HOME"
    export PATH="$PWD/bin:$PATH"

    mix() {
      (cd web && command mix "$@")
    }

    acceptance-test() {
      (cd acceptance-tests && npm test -- "$@")
    }

    echo "Memba dev environment"
    echo "Web app: web/"
    echo "Acceptance tests: acceptance-tests/"
    elixir --version
  '';
}
