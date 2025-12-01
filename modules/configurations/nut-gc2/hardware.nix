{ lib, inputs, ... }:
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
      dhcpcd.enable = false;
      usePredictableInterfaceNames = lib.mkForce true;
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
