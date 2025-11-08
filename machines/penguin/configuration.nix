{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (import ../../lib) collectNixFiles;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./disko-config.nix
    ./hardware-configuration.nix
  ]
  ++ collectNixFiles ../../modules/common
  ++ collectNixFiles ../../modules/nixos;
  config = {
    # age.secrets.k3s.file = ../../../secrets/k3s.age;
    users.users.yadunut.linger = true;
    nut = {
      users.enable = true;
      sane-defaults.enable = true;
      nvidia.enable = true;
    };

    boot = {
      tmp.cleanOnBoot = true;
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      initrd.network = {
        enable = true;
        ssh = {
          enable = true;
          hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
          authorizedKeys = lib.concatLists (
            lib.mapAttrsToList (
              name: user: if lib.elem "wheel" user.extraGroups then user.openssh.authorizedKeys.keys else [ ]
            ) config.users.users
          );
        };
      };
    };
    time.timeZone = "Asia/Singapore";

    networking = {
      networkmanager.enable = true;
      nftables.enable = false;
      firewall = {
        enable = true;
        allowedTCPPorts = [
          22
          3000
          3001
        ];
        trustedInterfaces = [
          "tailscale0"
          "ztxh6lvd6t"
        ];
      };
    };
    services = {
      openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
      };
      tailscale.enable = true;
      zerotierone = {
        enable = true;
        joinNetworks = [ "23992b9a659115b6" ];
      };
    };
    environment.systemPackages = with pkgs; [
      git
      neovim
      btop
    ];

    virtualisation.podman = {
      enable = true;
      dockerCompat = false;
      defaultNetwork.settings.dns_enabled = true;
    };
    system.stateVersion = "25.11";
  };
}
