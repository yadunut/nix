{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (import ../../lib) collectNixFiles;
  ip = "10.222.0.249";
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
    users.users.yadunut.linger = true;
    nut = {
      users.enable = true;
      sane-defaults.enable = true;
      nvidia.enable = true;
      k3s = {
        enable = true;
        role = "agent";
        tokenFile = config.age.secrets.k3s.path;
        clusterInit = false;
        serverAddr = "https://10.222.0.13:6443";
        nodeIp = ip;
        iface = "ztxh6lvd6t";
        nvidia = true;
      };
    };
    networking = {
      hostName = "penguin";
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

    home-manager = {
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      users.yadunut.imports = [
        ./homes/yadunut.nix
        inputs.nixvim.homeModules.nixvim
      ];
    };

    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    services = {
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
    clan.core.networking.targetHost = "root@${ip}";
  };
}
