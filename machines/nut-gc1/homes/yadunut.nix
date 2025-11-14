{
  pkgs,
  ...
}:
let
  inherit (import ../../../lib) collectNixFiles;
  config = {
    nut = {
      zsh.enable = true;
      neovim.enable = true;
    };
    home.username = "yadunut";
    home.packages = with pkgs; [
      ouch
      rsync
      zellij
    ];

    programs.home-manager.enable = true;
    home.stateVersion = "25.11";
  };
in
{
  imports = collectNixFiles ../../../modules/home;
  inherit config;
}
