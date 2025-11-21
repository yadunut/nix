{ ... }:
{
  perSystem =
    { inputs', ... }:
    {
      make-shells.default.packages = [
        inputs'.agenix.packages.default
      ];
    };
}
