{
  lib,
  inputs,
  ...
}:
{
  configurations.nixos.premhome-eagle-1.module = {
    imports = [ inputs.nixpkgs.nixosModules.notDetected ];

    boot.initrd.availableKernelModules = [
      "uhci_hcd"
      "ehci_pci"
      "ahci"
      "virtio_pci"
      "virtio_scsi"
      "sd_mod"
      "sr_mod"
    ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ ];

    networking.useDHCP = lib.mkDefault true;

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
