{
  inputs,
  self,
  config,
  hosts,
  ...
}:
{
  flake =
    let
      clan = inputs.clan-core.lib.clan {
        inherit self;
        specialArgs = { inherit inputs; };
        imports = with config.flake.modules.clan; [
          base
          wireguard
          zerotier
        ];
      };
    in
    {
      # inherit (clan.config) clanInternals;
      inherit (clan.config) clanInternals nixosConfigurations darwinConfigurations;
      clan = clan.config;
      modules.clan.base =
        { ... }:
        {
          meta.name = "nut-clan";
          meta.tld = "nut";
          inventory.machines = builtins.mapAttrs (
            name: cfg:
            {
              deploy.targetHost = "${cfg.user}@${cfg.targetIp}";
            }
            // (if cfg ? extraArgs then cfg.extraArgs else { })
          ) hosts.machines;
        };
    };

  perSystem =
    { inputs', ... }:
    {
      make-shells.default.packages = [
        inputs'.clan-core.packages.clan-cli
      ];
    };
}
