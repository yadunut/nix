{
  config,
  ...
}:
let
  hostname = "penguin";
  hosts = import ../../../hosts.nix;
  ip = hosts.machines.${hostname}.ip;
  serverIp = hosts.machines.nut-gc1.ip;
  nixosModules = config.flake.modules.nixos;
  homeManagerModules = config.flake.modules.homeManager;
in
{
  configurations.nixos.${hostname}.module =
    { config, ... }:
    {
      imports = with nixosModules; [
        base
        yadunut
        home-manager
        nvidia
        zerotier
        k3s
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
        hostName = hostname;
        networkmanager.enable = true;
        nftables.enable = false;
        firewall = {
          enable = true;
          allowedTCPPorts = [
            3000
            3001
          ];
          trustedInterfaces = [ "tailscale0" ];
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
