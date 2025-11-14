{
  inputs,
  pkgs,
  # lib,
  # specialArgs,
  # config,
  # options,
  # _class,
  # modulesPath,
  # _prefix,
  # darwinConfig,
  # osConfig,
  # osClass,
  ...
}:
let
  inherit (import ../../../lib) collectNixFiles;
  keys = import ../../../keys.nix;
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
      pkgs.cachix
      pkgs.ouch

      pkgs.nil
      pkgs.nixd

      pkgs.claude-code
      pkgs.codex
      pkgs.amp-cli
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
