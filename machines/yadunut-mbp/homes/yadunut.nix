{
  inputs,
  pkgs,
  ...
}:
let
  inherit (import ../../../lib) collectNixFiles;
  keys = import ../../../hosts.nix;
  config = {
    nut = {
      git = {
        enable = true;
        gpgProgram = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        signingKey = keys.user.yadunut;
      };
      zsh.enable = true;
      neovim.enable = true;
    };
    home.username = "yadunut";
    home.packages = [
      pkgs.entr
      pkgs.jq
      pkgs.just
      pkgs.rsync
      pkgs.codex
      pkgs.dive
      pkgs.ouch

      pkgs.nil
      pkgs.nixd

      pkgs.claude-code
      # pkgs.amp-cli
    ];

    nixpkgs.config.allowUnfree = true;
    programs.home-manager.enable = true;
    home.stateVersion = "25.05";
  };
in
{
  imports = collectNixFiles ../../../modules/home;
  inherit config;
}
