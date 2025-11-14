{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    mkMerge
    types
    ;
in
{
  options.nut.k3s = {
    enable = mkEnableOption "My k3s cluster";
    tokenFile = mkOption {
      type = types.nonEmptyStr;
    };
    role = mkOption {
      type = types.enum [
        "server"
        "agent"
      ];
      default = "agent";
    };
    clusterInit = mkOption {
      type = types.bool;
      default = false;
    };
    serverAddr = mkOption {
      type = types.nonEmptyStr;
      default = "server";
    };
    nodeIp = mkOption {
      type = types.nonEmptyStr;
    };
    iface = mkOption {
      type = types.nonEmptyStr;
    };
    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
    nvidia = mkOption {
      type = types.bool;
      default = false;
    };
  };
  config =
    let
      cfg = config.nut.k3s;
      isServer = cfg.role == "server";
    in
    mkIf cfg.enable (mkMerge [
      {
        services.k3s = {
          enable = true;
          role = cfg.role;
          tokenFile = cfg.tokenFile;
          clusterInit = isServer && cfg.clusterInit;
          serverAddr = cfg.serverAddr;
          extraFlags = [
            "--node-ip ${cfg.nodeIp}"
            "--flannel-iface ${cfg.iface}"
          ]
          ++ cfg.extraFlags;
        };
        environment.systemPackages = [ pkgs.nfs-utils ];
        services.openiscsi = {
          enable = true;
          name = "iqn.2016-04.com.open-iscsi:${config.networking.hostName}";
        };
        systemd.tmpfiles.rules = [
          "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
        ];
      }
      (mkIf cfg.nvidia {
        hardware.nvidia-container-toolkit.enable = true;
        hardware.nvidia-container-toolkit.mount-nvidia-executables = true;
        environment.systemPackages = [ pkgs.nvidia-container-toolkit ];
      })
    ]);
}
