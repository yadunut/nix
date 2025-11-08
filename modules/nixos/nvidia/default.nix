{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.nut.nvidia;
in
{
  options.nut.nvidia = {
    enable = mkEnableOption "NVIDIA driver support";
  };

  config = mkIf cfg.enable {
    nixpkgs.config = {
      cudaSupport = true;
    };
    hardware.graphics.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia.open = true;
  };
}
