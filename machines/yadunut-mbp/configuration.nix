{ ... }@args:
{
  imports = [
    ../../modules/darwin/sane-defaults
  ];
  system.primaryUser = "yadunut";
  users.users."yadunut" = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJXOpmWsAnl2RtOuJJMRUx+iJTwf2RWJ1iS3FqXJFzFG"
    ];
  };
  users.users."root" = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJXOpmWsAnl2RtOuJJMRUx+iJTwf2RWJ1iS3FqXJFzFG"
    ];
  };

  security.pam.services.sudo_local.touchIdAuth = true;
  nixpkgs.hostPlatform = "aarch64-darwin";
  clan.core.networking.targetHost = "root@localhost";
  nix.enable = false; # since we're using nix darwin
  system.stateVersion = 6;
}
