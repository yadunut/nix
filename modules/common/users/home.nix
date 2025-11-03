{
  _class,
  config,
  lib,
  pkgs,
  ...
}:
let
  config = {
    nut = {
      git = {
        enable = true;
        gpgProgram = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        signingKey = "~/.ssh/yadunut_ed25519.pub";
      };
      zsh.enable = true;
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
  imports = [
    config
    ../../home/git
    ../../home/zsh
  ];
}
