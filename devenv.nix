{ pkgs, ... }:

let
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
            paths = [ pkgs.git ];
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
    workingDir = "/workspace/memba";
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
