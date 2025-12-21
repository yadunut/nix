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
        "discord"
        "fantastical"
        "freecad"
        "ghostty"
        "google-chrome"
        "iina"
        "keybase"
        "kicad"
        "launchcontrol"
        "ledger-live"
        "lens"
        "logitech-g-hub"
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
