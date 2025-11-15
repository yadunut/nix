{
  _class,
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.nut.sane-defaults;
  nixosModule = mkIf cfg.enable {
    time.timeZone = "Asia/Singapore";
    environment.systemPackages = with pkgs; [
      cachix
      git
      neovim
      btop
    ];

    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };

    security.sudo.wheelNeedsPassword = false;
    nixpkgs.config = {
      allowUnfree = true;
    };
    nix = {
      optimise = {
        automatic = true;
      };
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        substituters = [
          "https://nix-community.cachix.org"
          "https://cache.nixos.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        ];
        trusted-users = [
          "@nixbld"
          "root"
          "yadunut"
        ];
      };
    };

  };
  darwinModule = mkIf cfg.enable {
    time.timeZone = "Asia/Singapore";
    nixpkgs.config = {
      allowUnfree = true;
    };
    system.defaults = {
      NSGlobalDomain = {
        InitialKeyRepeat = 10;
        KeyRepeat = 1;
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;
      };
      dock.autohide = true;
      dock.autohide-delay = 0.0;
    };
    security.pam.services.sudo_local.touchIdAuth = true;
  };
in
{
  imports = [
    (lib.optionalAttrs (_class == "nixos") nixosModule)
    (lib.optionalAttrs (_class == "darwin") darwinModule)
  ];
  options.nut.sane-defaults = {
    enable = mkEnableOption "enable sane defaults";
  };
}
