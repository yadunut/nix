{
  lib,
  inputs,
  ...
}:
{
  configurations.nixos.nut-gc2.module = {
    imports = [ inputs.nixpkgs.nixosModules.notDetected ];

    boot.initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "virtio_pci"
      "virtio_scsi"
      "ahci"
      "sd_mod"
      "sr_mod"
      "virtio_blk"
    ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-amd" ];
    boot.extraModulePackages = [ ];
    services.udev.extraRules = ''
      ATTR{address}=="00:72:f1:f7:47:db", NAME="ens3"
    '';
    networking = {
      useDHCP = lib.mkDefault true;
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

    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
