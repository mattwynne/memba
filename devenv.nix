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
  ];

  languages.elixir.enable = true;

  env = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
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
    workingDir = "/workspace";
  };

  enterShell = ''
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
