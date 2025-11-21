{
  config,
  ...
}:
{
  configurations.darwin.yadunut-mbp.module = {
    imports = with config.flake.modules.darwin; [
      base
      home-manager
    ];
    home-manager = {
      users.yadunut.imports = [
        config.flake.modules.homeManager.nixvim
        config.flake.modules.homeManager.base
        (
          { pkgs, ... }:
          let
            keys = import ../../../hosts.nix;
          in
          {
            nut = {
              git = {
                gpgProgram = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
                signingKey = keys.user.yadunut;
              };
            };
            home = {
              username = "yadunut";
              packages = [
                pkgs.entr
                pkgs.jq
                pkgs.just
                pkgs.rsync
                pkgs.dive
                pkgs.ouch

                pkgs.nil
                pkgs.nixd

                pkgs.claude-code
                pkgs.codex
              ];
              stateVersion = "25.05";
            };

            nixpkgs.config.allowUnfree = true;
            programs.home-manager.enable = true;
          }
        )
      ];
    };
    homebrew = {
      enable = true;
      onActivation.cleanup = "zap";
      greedyCasks = true;
      brews = [ "container" ];
      casks = [
        "1password"
        "1password-cli"
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
    nixpkgs.hostPlatform = "aarch64-darwin";
    nix.enable = false; # since we're using nix darwin and determinate nix
    system.stateVersion = 6;
  };
}
