{ ... }:
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      time.timeZone = "Asia/Singapore";
      environment.systemPackages = with pkgs; [
        cachix
        git
        neovim
        btop
      ];
      security.sudo.wheelNeedsPassword = false;
    };
  flake.modules.darwin.base =
    { ... }:
    {
      time.timeZone = "Asia/Singapore";
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
}
