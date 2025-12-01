{ config, ... }:
let
  hostName = "premhome-falcon-1";
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
      ];
      home-manager.users.yadunut.imports = with homeManagerModules; [
        nixvim
        base
        yadunut
      ];
      nut = {
        boot.loader = "systemd";
      };

      networking.hostName = hostName;

      services = {
        qemuGuest.enable = true;
      };

      system.stateVersion = "24.11";
    };
}
