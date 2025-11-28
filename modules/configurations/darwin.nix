{ lib, config, ... }:
{
  options.configurations.darwin = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options.module = lib.mkOption {
          type = lib.types.deferredModule;
        };
      }
    );
  };
  config.flake.modules.clan.base =
    { ... }:
    {
      machines = lib.mapAttrs (
        _:
        { module }:
        {
          imports = [ module ];
        }
      ) config.configurations.darwin;
    };
}
