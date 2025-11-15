{
  # Ensure this is unique among all clans you want to use.
  meta.name = "nut-clan";
  meta.tld = "nut";

  inventory.machines =
    let
      machinesConfig = import ./hosts.nix;
    in
    {
      yadunut-mbp.machineClass = "darwin";
    }
    // builtins.mapAttrs (name: cfg: {
      deploy.targetHost = "${cfg.user}@${cfg.ip}";
    }) machinesConfig.machines;

  inventory.instances = { };

  # Additional NixOS configuration can be added here.
  # machines/jon/configuration.nix will be automatically imported.
  # See: https://docs.clan.lol/guides/more-machines/#automatic-registration
  machines = {
  };
}
