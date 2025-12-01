{ hosts, lib, ... }:
let
  controllers = lib.filterAttrs (name: machine: machine ? publicIp) hosts.machines;
  peers = lib.filterAttrs (name: machine: !(machine ? publicIp)) hosts.machines;

  # Create controller machines dynamically
  controllerMachines = lib.mapAttrs (name: machine: {
    settings.endpoint = machine.publicIp;
  }) controllers;

  peerMachines = lib.mapAttrs (name: machine: {
    settings.controller = "nut-gc1";
  }) peers;
in
{
  flake.modules.nixos.base =
    { config, ... }:
    lib.mkIf (config.networking.wireguard.interfaces ? wireguard) {
      networking.firewall.trustedInterfaces = [ "wireguard" ];
      networking.firewall.extraForwardRules = ''
        iifname "wireguard" accept
      '';
    };
  flake.modules.clan.wireguard = {
    inventory.instances.wireguard = {
      module.name = "wireguard";
      module.input = "clan-core";
      roles.controller = {
        machines = controllerMachines;
      };
      roles.peer.machines = peerMachines;

    };
  };
}
