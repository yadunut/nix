{ hosts, lib, ... }:
let
  controllers = lib.filterAttrs (name: machine: machine ? publicIp) hosts.machines;
  peers = lib.filterAttrs (name: machine: !(machine ? publicIp)) hosts.machines;

  # Create controller machines dynamically
  controllerMachines = lib.mapAttrs' (name: machine: lib.nameValuePair name { }) controllers;

  peerMachines = lib.mapAttrs' (
    name: machine:
    lib.nameValuePair name {
      settings.controller = "nut-gc1";
    }
  ) peers;
in
{
  flake.modules.clan.wireguard = {
    inventory.instances.wireguard = {
      module.name = "wireguard";
      module.input = "clan-core";
      roles.controller = {
        machines = controllerMachines;
        settings = {
          endpoint = hosts.machines.nut-gc1.publicIp;
          port = 51820;
        };
      };
      roles.peer.machines = peerMachines;

    };
  };
}
