{
  config,
  lib,
  hosts,
  ...
}:
let
  toInterfaceName = config.flake.lib.zerotier.toInterfaceName;
in
{
  flake.modules.nixos.base =
    { config, ... }:
    lib.mkIf (config.clan.core.networking ? zerotier) {
      networking.firewall.trustedInterfaces =
        let
          interfaceName = toInterfaceName config.clan.core.networking.zerotier.networkId;
        in
        [ interfaceName ];
    };
  flake.modules.clan.zerotier =
    let
      moons = lib.filterAttrs (name: machine: machine ? publicIp) hosts.machines;
      moonMachines = lib.mapAttrs (name: machine: {
        settings.stableEndpoints = [ machine.publicIp ];
      }) moons;
    in
    {
      inventory.instances.zerotier = {
        module.name = "zerotier";
        module.input = "clan-core";
        roles.controller.machines.nut-gc1 = { };
        roles.peer.tags.all = { };
        roles.moon.machines = moonMachines;
      };
    };

  flake.lib.zerotier =
    let
      # Integer mod using truncating division.
      mod = a: b: a - b * (builtins.div a b);

      pow = base: exp: if exp == 0 then 1 else base * (pow base (exp - 1));

      hexDigit = {
        "0" = 0;
        "1" = 1;
        "2" = 2;
        "3" = 3;
        "4" = 4;
        "5" = 5;
        "6" = 6;
        "7" = 7;
        "8" = 8;
        "9" = 9;
        "a" = 10;
        "A" = 10;
        "b" = 11;
        "B" = 11;
        "c" = 12;
        "C" = 12;
        "d" = 13;
        "D" = 13;
        "e" = 14;
        "E" = 14;
        "f" = 15;
        "F" = 15;
      };

      hexToInt =
        s:
        let
          len = builtins.stringLength s;
          go =
            i: acc:
            if i == len then
              acc
            else
              let
                ch = builtins.substring i 1 s;
                val = hexDigit.${ch};
              in
              go (i + 1) (acc * 16 + val);
        in
        go 0 0;

      alphabet = "abcdefghijklmnopqrstuvwxyz234567";

      encode32 =
        n:
        if n == 0 then
          ""
        else
          let
            q = builtins.div n 32;
            r = mod n 32;
            ch = builtins.substring r 1 alphabet;
          in
          encode32 q + ch;

      # Matches the ZeroTier CLI hashing for interface names (no index offset).
      toInterfaceName =
        networkHex:
        let
          net = hexToInt networkHex;
          hashed = mod (builtins.bitXor net (builtins.div net (pow 2 (3 * 8)))) (pow 2 (5 * 8));
        in
        "zt${encode32 hashed}";
    in
    {
      inherit toInterfaceName;
    };
}
