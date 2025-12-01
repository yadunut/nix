{ config, ... }:
let
  hostName = "nut-gc2";
  nixosModules = config.flake.modules.nixos;
  homeManagerModules = config.flake.modules.homeManager;
in
{
  configurations.nixos.${hostName}.module =
    { config, ... }:
    {
      imports = with nixosModules; [
        base
        garage
        home-manager
      ];
      home-manager.users.yadunut.imports = with homeManagerModules; [
        base
        nixvim
        yadunut
      ];

      nut = {
        garage.metadataDir = "/srv/garage/meta";
        garage.dataDir = "/srv/garage/data";
        garage.publicAddrSubnet = config.clan.core.networking.zerotier.subnet;
        boot.loader = "grub";
      };

      networking.hostName = hostName;
      system.stateVersion = "25.11";
    };
}
