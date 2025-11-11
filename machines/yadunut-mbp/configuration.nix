{ pkgs, inputs, ... }:
let
  inherit (import ../../lib) collectNixFiles;
in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ]
  ++ collectNixFiles ../../modules/common;
  # ++ collectNixFiles ../../modules/darwin;
  config = {
    system.primaryUser = "yadunut";

    nut = {
      users.enable = true;
      sane-defaults.enable = true;
    };

    nix-homebrew = {
      enable = true;
      user = "yadunut";
      autoMigrate = true;
    };

    # # Home Manager configuration
    home-manager.useUserPackages = true;
    home-manager.users.yadunut = {
      imports = [
        ./homes/yadunut.nix
        inputs.nixvim.homeModules.nixvim
      ];
    };

    nixpkgs.config.allowUnfree = true;

    fonts.packages = [ pkgs.jetbrains-mono ];
    homebrew = {
      enable = true;
      onActivation.cleanup = "zap";
      greedyCasks = true;
      brews = [
        "container"
      ];
      casks = [
        "1password"
        "1password-cli"
        "calibre"
        "coconutbattery"
        "daisydisk"
        "darktable"
        "datagrip"
        "discord"
        "fantastical"
        "fastmail"
        "ghostty"
        "google-chrome"
        "iina"
        "keybase"
        "kicad"
        "launchcontrol"
        "ledger-live"
        "lens"
        "logitech-g-hub"
        "logseq"
        "loom"
        "lulu"
        "obs"
        "obsidian"
        "protonvpn"
        "raycast"
        "selfcontrol"
        "skim"
        "slack"
        "spotify"
        "steam"
        "syncthing-app"
        "tailscale"
        "tailscale-app"
        "telegram"
        "the-unarchiver"
        "transmission"
        "visual-studio-code"
        "whatsapp"
        "xcodes-app"
        "yaak"
        "zen"
        "zerotier-one"
        "zoom"
        "zotero"
      ];
    };

    nixpkgs.hostPlatform = "aarch64-darwin";
    clan.core.networking.targetHost = "root@localhost";
    nix.enable = false; # since we're using nix darwin and determinate nix
    system.stateVersion = 6;
  };
}
