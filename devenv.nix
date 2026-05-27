{ pkgs, ... }:

{
  packages = with pkgs; [
    adrgen
    argc
    devenv
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
    copyToRoot = null;
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
