{
  ...
}:
{
  flake.modules.nixos.nvidia = {
    nixpkgs.config = {
      cudaSupport = true;
    };
    hardware.graphics.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia.open = false;
  };
}
