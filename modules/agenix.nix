{ inputs, ... }:
{
  flake.modules.nixos.agenix = {
    imports = [
      inputs.agenix.nixosModules.default
    ];
  };
  perSystem =
    { inputs', ... }:
    {
      make-shells.default.packages = [
        inputs'.agenix.packages.default
      ];
    };
}
