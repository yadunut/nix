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
  ip = machinesConfig.machines.penguin.ip;
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
    users.users.yadunut.linger = true;
    nut = {
      users.enable = true;
      sane-defaults.enable = true;
      nvidia.enable = true;
      zerotier.enable = true;
      boot.loader = "systemd";
      k3s = {
        enable = true;
        role = "agent";
        tokenFile = config.age.secrets.k3s.path;
        serverAddr = "https://10.222.0.13:6443";
        nodeIp = ip;
        iface = "ztxh6lvd6t";
        nvidia = true;
      };
    };
    networking = {
      hostName = "penguin";
      networkmanager.enable = true;
      nftables.enable = false;
      firewall = {
        enable = true;
        allowedTCPPorts = [
          22
          3000
          3001
        ];
        trustedInterfaces = [ "tailscale0" ];
      };
    };

    nut.home-manager = {
      enable = true;
      userImports = [
        ./homes/yadunut.nix
        inputs.nixvim.homeModules.nixvim
      ];
    };

    services.tailscale.enable = true;

    virtualisation.podman = {
      enable = true;
      dockerCompat = false;
      defaultNetwork.settings.dns_enabled = true;
    };
    system.stateVersion = "25.11";
  };
}
