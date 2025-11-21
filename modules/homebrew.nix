{ inputs, ... }:
{
  flake.modules.darwin.base =
    { ... }:
    {
      imports = [
        inputs.nix-homebrew.darwinModules.nix-homebrew
      ];
      nix-homebrew = {
        enable = true;
        user = "yadunut";
        autoMigrate = true;
      };
      homebrew = {
        enable = true;
        onActivation.cleanup = "zap";
        greedyCasks = true;
      };
    };
}
