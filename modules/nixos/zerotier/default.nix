{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.nut.zerotier;
in
{
  options.nut.zerotier = {
    enable = mkEnableOption "Zerotier Network";
  };

  config = mkIf cfg.enable {
    services.zerotierone = {
      enable = true;
      joinNetworks = [ "23992b9a659115b6" ];
    };
    networking.firewall.trustedInterfaces = [ "ztxh6lvd6t" ];
  };
}
