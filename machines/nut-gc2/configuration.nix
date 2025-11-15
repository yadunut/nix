{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (import ../../lib) collectNixFiles;
  ip = "10.222.0.87";
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    ./disko-config.nix
    ./hardware-configuration.nix
  ]
  ++ collectNixFiles ../../modules/common
  ++ collectNixFiles ../../modules/nixos;
  config = {
    age.secrets.k3s.file = ../../secrets/k3s.age;
    nut = {
      users.enable = true;
      sane-defaults.enable = true;
      boot.loader = "grub";
      zerotier.enable = true;
      k3s = {
        enable = true;
        role = "agent";
        tokenFile = config.age.secrets.k3s.path;
        serverAddr = "https://10.222.0.13:6443";
        nodeIp = ip;
        iface = "ztxh6lvd6t";
      };
    };
    networking = {
      hostName = "nut-gc2";
      nameservers = [
        "1.1.1.1"
        "8.8.8.8"
      ];
      defaultGateway = {
        address = "103.149.46.126";
        interface = "ens3";
      };
      defaultGateway6 = {
        address = "2a11:8083:11::1";
        interface = "ens3";
      };
      dhcpcd.enable = false;
      usePredictableInterfaceNames = lib.mkForce true;
      interfaces = {
        ens3 = {
          ipv4.addresses = [
            {
              address = "103.149.46.7";
              prefixLength = 25;
            }
          ];
          ipv6.addresses = [
            {
              address = "2a11:8083:11:13d4::a";
              prefixLength = 64;
            }
            {
              address = "fe80::272:f1ff:fef7:47db";
              prefixLength = 64;
            }
          ];
          ipv4.routes = [
            {
              address = "103.149.46.126";
              prefixLength = 32;
            }
          ];
          ipv6.routes = [
            {
              address = "2a11:8083:11::1";
              prefixLength = 128;
            }
          ];
        };
      };
      firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
        trustedInterfaces = [ "tailscale0" ];
      };
    };

    home-manager = {
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      users.yadunut.imports = [
        ../../homes/yadunut.nix
      ];
    };

    services = {
      tailscale.enable = true;
      udev.extraRules = ''
        ATTR{address}=="00:72:f1:f7:47:db", NAME="ens3"
      '';
    };

    system.stateVersion = "25.11";
    clan.core.networking.targetHost = "yadunut@${ip}";
  };
}
