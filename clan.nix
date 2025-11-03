{
  # Ensure this is unique among all clans you want to use.
  meta.name = "nut-clan";
  meta.tld = "nut";

  inventory.machines = {
    yadunut-mbp.machineClass = "darwin";
  };

  inventory.instances = { };

  # Additional NixOS configuration can be added here.
  # machines/jon/configuration.nix will be automatically imported.
  # See: https://docs.clan.lol/guides/more-machines/#automatic-registration
  machines = {
    "yadunut-mbp" = {
      nixpkgs.hostPlatform = "aarch64-darwin";
      clan.core.networking.targetHost = "root@localhost";
      system.stateVersion = 6;
      nix.enable = false;
      users.users."yadunut".openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJXOpmWsAnl2RtOuJJMRUx+iJTwf2RWJ1iS3FqXJFzFG"
      ];
      users.users."root".openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJXOpmWsAnl2RtOuJJMRUx+iJTwf2RWJ1iS3FqXJFzFG"
      ];
    };
  };
}
