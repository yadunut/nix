{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    types
    ;
in
{
  options.nut.boot = {
    loader = mkOption {
      type = types.enum [
        "grub"
        "systemd"
      ];
      default = "grub";
    };
  };
  config =
    let
      cfg = config.nut.boot;
      isGrub = cfg.loader == "grub";
      isSystemd = cfg.loader == "systemd";
    in
    lib.mkMerge [
      { boot.tmp.cleanOnBoot = true; }
      (mkIf isGrub {
        boot.loader.grub.enable = true;
      })
      (mkIf isSystemd {
        boot.loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };
      })
    ];
}
