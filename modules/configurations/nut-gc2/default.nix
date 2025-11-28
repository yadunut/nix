{ config, hosts, ... }:
let
  hostName = "nut-gc2";
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
        tailscale
        yadunut
        zerotier
      ];
      home-manager.users.yadunut.imports = with homeManagerModules; [
        nixvim
        base
        yadunut
      ];

      age.secrets.k3s.file = ../../../secrets/k3s.age;
      nut = {
        boot.loader = "grub";
        k3s = {
          role = "agent";
          tokenFile = config.age.secrets.k3s.path;
          serverAddr = "https://${serverIp}:6443";
          nodeIp = ip;
          iface = "ztxh6lvd6t";
        };
      };

      networking.hostName = hostName;
      system.stateVersion = "25.11";
    };
}
