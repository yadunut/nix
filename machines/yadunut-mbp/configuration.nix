{ pkgs, ... }:
let
  keys = import ../../keys.nix;
in
{
  imports = [
    ../../modules/darwin/sane-defaults
  ];
  system.primaryUser = "yadunut";
  users.users."yadunut" = {
    openssh.authorizedKeys.keys = [ keys.yadunut ];
  };
  users.users."root" = {
    openssh.authorizedKeys.keys = [ keys.yadunut ];
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    greedyCasks = true;
    casks = [
      "1password"
      "1password-cli"
      "calibre"
      "cardhop"
      "coconutbattery"
      "daisydisk"
      "darktable"
      "datagrip"
      "discord"
      "fantastical"
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
      "skim"
      "slack"
      "spotify"
      "steam"
      "superwhisper"
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

  fonts.packages = [ pkgs.jetbrains-mono ];

  security.pam.services.sudo_local.touchIdAuth = true;

  nixpkgs.hostPlatform = "aarch64-darwin";
  clan.core.networking.targetHost = "root@localhost";
  nix.enable = false; # since we're using nix darwin
  system.stateVersion = 6;
}
