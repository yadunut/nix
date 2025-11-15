{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (import ../../lib) collectNixFiles;
  machinesConfig = import ../../hosts.nix;
  hostName = "premhome-eagle-1";
  ip = machinesConfig.machines."${hostName}".ip;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    ./disko-config.nix
    ./hardware-configuration.nix
  ]
  ++ collectNixFiles ../../modules/common
  ++ collectNixFiles ../../modules/nixos;
  config = {
    age.secrets.k3s.file = ../../secrets/k3s.age;
    nut = {
      users.enable = true;
      sane-defaults.enable = true;
      boot.loader = "systemd";
      zerotier.enable = true;
      k3s = {
        enable = true;
        role = "agent";
        tokenFile = config.age.secrets.k3s.path;
        serverAddr = "https://10.222.0.13:6443";
        nodeIp = ip;
        iface = "ztxh6lvd6t";
      };
      home-manager = {
        enable = true;
        userImports = [
          ../../homes/yadunut.nix
        ];
      };
    };

    networking = {
      hostName = hostName;
      nameservers = [
        "1.1.1.1"
        "8.8.8.8"
      ];
      firewall = {
        enable = true;
        allowedTCPPorts = [
          22
        ];
        trustedInterfaces = [ "tailscale0" ];
      };
    };

    services = {
      tailscale.enable = true;
      qemuGuest.enable = true;
    };

    system.stateVersion = "24.11";
  };
}
