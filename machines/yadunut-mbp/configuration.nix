{ pkgs, ... }:
let
  keys = import ../../keys.nix;
in
{
  imports = [
    ../../modules/darwin/sane-defaults
  ];
  system.primaryUser = "yadunut";
  users.users."yadunut" = {
    openssh.authorizedKeys.keys = [ keys.yadunut ];
  };
  users.users."root" = {
    openssh.authorizedKeys.keys = [ keys.yadunut ];
  };
    ];
  };

  security.pam.services.sudo_local.touchIdAuth = true;
  nixpkgs.hostPlatform = "aarch64-darwin";
  clan.core.networking.targetHost = "root@localhost";
  nix.enable = false; # since we're using nix darwin
  system.stateVersion = 6;
}
