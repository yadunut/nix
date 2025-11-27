{ lib, ... }:
{
  flake.modules.nixos.base =
    { config, ... }:
    {
      options.nut.boot = {
        loader = lib.mkOption {
          type = lib.types.enum [
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
          (lib.mkIf isGrub {
            boot.loader.grub.enable = true;
          })
          (lib.mkIf isSystemd {
            boot.loader = {
              systemd-boot.enable = true;
              efi.canTouchEfiVariables = true;
            };
          })
        ];
    };
}
