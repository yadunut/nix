{ ... }:
{
  perSystem =
    { inputs', ... }:
    {
      make-shells.default.packages = [
        inputs'.clan-core.packages.clan-cli
      ];
    };
}
