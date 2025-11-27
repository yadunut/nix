{ config, ... }:
let
  hostName = "nut-gc1";
  hosts = import ../../../hosts.nix;
  ip = hosts.machines.${hostName}.ip;
  nixosModules = config.flake.modules.nixos;
  homeManagerModules = config.flake.modules.homeManager;
in
{
  configurations.nixos.${hostName}.module =
    { config, ... }:
    {
      imports = with nixosModules; [
        base
        yadunut
        home-manager
        zerotier
        k3s
        tailscale
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
          role = "server";
          tokenFile = config.age.secrets.k3s.path;
          nodeIp = ip;
          iface = "ztxh6lvd6t";
        };
      };

      services.tailscale.enable = true;
      networking = {
        hostName = hostName;
        firewall = {
          allowedTCPPorts = [
            80
            443
          ];
        };
      };
      system.stateVersion = "25.11";
    };
}
