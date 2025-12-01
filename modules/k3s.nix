{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    mkMerge
    types
    ;
  inherit (config.flake.lib.zerotier) toInterfaceName;
in

{
  flake.modules.nixos.k3s =
    { config, pkgs, ... }:
    let
      interfaceName = toInterfaceName config.clan.networking.zerotier.networkId;
      nodeIp = config.clan.core.vars.generators.zerotier.files.zerotier-ip.value;
    in
    {
      options.nut.k3s = {
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
          type = types.str;
          default = "";
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
        mkMerge [
          {
            services.k3s = {
              enable = true;
              role = cfg.role;
              tokenFile = cfg.tokenFile;
              clusterInit = isServer && cfg.clusterInit;
              serverAddr = cfg.serverAddr;
              extraFlags = [
                "--node-ip ${nodeIp}"
                "--flannel-iface ${interfaceName}"
              ]
              ++ (lib.optionals isServer [
                "--disable=servicelb"
                "--disable=traefik"
                "--flannel-backend=host-gw"
                "--tls-san ${nodeIp}"
              ])
              ++ cfg.extraFlags;
            };
            boot.kernel.sysctl = {
              "net.ipv4.ip_forward" = 1;
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
        ];
    };
}
