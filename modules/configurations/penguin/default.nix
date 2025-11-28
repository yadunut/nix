{ config, hosts, ... }:
let
  hostName = "penguin";
  ip = hosts.machines.${hostName}.ip;
  serverIp = hosts.machines.nut-gc1.ip;
  nixosModules = config.flake.modules.nixos;
  homeManagerModules = config.flake.modules.homeManager;
in
{
  configurations.nixos.${hostName}.module =
    { config, ... }:
    {
      imports = with nixosModules; [
        base
        home-manager
        k3s
        nvidia
        tailscale
        yadunut
        zerotier
      ];
      home-manager.users.yadunut.imports = with homeManagerModules; [
        yadunut
        nixvim
        base
        penguin
      ];

      age.secrets.k3s.file = ../../../secrets/k3s.age;
      nut = {
        boot.loader = "systemd";
        k3s = {
          role = "agent";
          tokenFile = config.age.secrets.k3s.path;
          serverAddr = "https://${serverIp}:6443";
          nodeIp = ip;
          iface = "ztxh6lvd6t";
          nvidia = true;
        };
      };

      networking = {
        inherit hostName;
        networkmanager.enable = true;
        nftables.enable = false;
        firewall = {
          allowedTCPPorts = [
            3000
            3001
          ];
        };
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
