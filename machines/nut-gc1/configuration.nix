{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (import ../../lib) collectNixFiles;
  ip = "10.222.0.13";
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
      zerotier.enable = true;
      k3s = {
        enable = true;
        role = "server";
        tokenFile = config.age.secrets.k3s.path;
        clusterInit = true;
        nodeIp = ip;
        iface = "ztxh6lvd6t";
      };
    };
    networking = {
      hostName = "nut-gc1";
      nameservers = [
        "1.1.1.1"
        "8.8.8.8"
      ];
      defaultGateway = {
        address = "167.253.159.126";
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
              address = "167.253.159.47";
              prefixLength = 25;
            }
          ];
          ipv6.addresses = [
            {
              address = "2a11:8083:11:1021::a";
              prefixLength = 64;
            }
            {
              address = "fe80::6491:adff:feb9:6f2d";
              prefixLength = 64;
            }
          ];
          ipv4.routes = [
            {
              address = "167.253.159.126";
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
        allowedTCPPorts = [
          22
          80
          443
        ];
        trustedInterfaces = [ "tailscale0" ];
      };
    };

    home-manager = {
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      users.yadunut.imports = [
        ./homes/yadunut.nix
        inputs.nixvim.homeModules.nixvim
      ];
    };

    boot = {
      loader.grub.enable = true;
      kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
      };
    };

    services = {
      tailscale.enable = true;
      udev.extraRules = ''
        ATTR{address}=="00:72:f1:f7:47:db", NAME="ens3"
      '';
    };
    environment.systemPackages = with pkgs; [
      git
      neovim
      btop
    ];

    system.stateVersion = "25.11";
    clan.core.networking.targetHost = "yadunut@${ip}";
  };
}
