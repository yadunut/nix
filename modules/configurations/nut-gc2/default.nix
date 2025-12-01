{ config, ... }:
let
  hostName = "nut-gc2";
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
        yadunut
      ];
      home-manager.users.yadunut.imports = with homeManagerModules; [
        nixvim
        base
        yadunut
      ];

      nut = {
        boot.loader = "grub";
      };

      networking.hostName = hostName;
      system.stateVersion = "25.11";
    };
}
