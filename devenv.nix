{ pkgs, ... }:

{
  packages = with pkgs; [
    adrgen
    nodejs_22
  ];

  languages.elixir.enable = true;

  services.postgres = {
    enable = true;
    initialDatabases = [{ name = "memba_dev"; }];
  };

  enterShell = ''
    echo "Memba dev environment"
    elixir --version
  '';
}
