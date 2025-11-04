{
  _class,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.nut.sane-defaults;
  nixosModule = mkIf cfg.enable { };
  darwinModule = mkIf cfg.enable {
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
