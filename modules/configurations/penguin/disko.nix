{ inputs, ... }:
{
  configurations.nixos.penguin.module = {
    imports = [ inputs.disko.nixosModules.disko ];
    disko.devices = {
      disk = {
        disk1 = {
          type = "disk";
          device = "/dev/nvme1n1";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              crypt_p1 = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "crypt_p1";
                  passwordFile = "/tmp/disk.key";
                  settings = {
                    allowDiscards = true;
                  };
                };
              };
            };
          };
        };
        disk2 = {
          type = "disk";
          device = "/dev/nvme2n1";
          content = {
            type = "gpt";
            partitions = {
              crypt_p2 = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "crypt_p2";
                  settings = {
                    allowDiscards = true;
                  };
                  content = {
                    type = "btrfs";
                    extraArgs = [
                      "-d raid1"
                      "/dev/mapper/crypt_p1"
                    ];
                    subvolumes = {
                      "@" = { };
                      "@/root" = {
                        mountpoint = "/";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                      "@/home" = {
                        mountpoint = "/home";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                      "@/nix" = {
                        mountpoint = "/nix";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                      };
                      "@/swap" = {
                        # mountpoint = "/.swapvol";
                        # swap.swapfile.size = "64G";
                        mountOptions = [ "noatime" ];
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
