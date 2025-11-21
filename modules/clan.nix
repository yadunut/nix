{ inputs, self, ... }:
{
  # imports = [ inputs.clan-core.flakeModules.default ];
  flake =
    let
      hosts = import ../hosts.nix;
      clan = inputs.clan-core.lib.clan {
        inherit self;
        specialArgs = { inherit inputs; };
        imports = [
          {
            meta.name = "nut-clan";
            meta.tld = "nut";
            inventory.machines = builtins.mapAttrs (
              name: cfg:
              {
                deploy.targetHost = "${cfg.user}@${cfg.ip}";
              }
              // (if cfg ? extraArgs then cfg.extraArgs else { })
            ) hosts.machines;

            inventory.instances = { };
            machines = { };
          }
        ];
      };
    in
    {
      inherit (clan.config) clanInternals;
      clan = clan.config;
    };
  perSystem =
    { inputs', ... }:
    {
      make-shells.default.packages = [
        inputs'.clan-core.packages.clan-cli
      ];
    };
}
