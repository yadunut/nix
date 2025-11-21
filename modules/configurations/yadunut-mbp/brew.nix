{
  ...
}:
{
  configurations.darwin.yadunut-mbp.module = {
    homebrew = {
      enable = true;
      onActivation.cleanup = "zap";
      greedyCasks = true;
      brews = [ "container" ];
      casks = [
        "1password"
        "1password-cli"
        "autodesk-fusion"
        "bambu-studio"
        "calibre"
        "coconutbattery"
        "cursor"
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
  };
}
