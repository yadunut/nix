{ config, ... }:
let
  hostName = "penguin";
  nixosModules = config.flake.modules.nixos;
  homeManagerModules = config.flake.modules.homeManager;
in
{
  configurations.nixos.${hostName}.module =
    { ... }:
    {
      imports = with nixosModules; [
        base
        home-manager
        nvidia
        yadunut
      ];
      home-manager.users.yadunut.imports = with homeManagerModules; [
        yadunut
        nixvim
        base
        penguin
      ];

      nut = {
        boot.loader = "systemd";
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

      virtualisation.podman = {
        enable = true;
        dockerCompat = false;
        defaultNetwork.settings.dns_enabled = true;
      };

      system.stateVersion = "25.11";
    };
}
