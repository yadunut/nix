{ ... }:
{
  flake.modules.nixos.base =
    { ... }:
    {
      nixpkgs.config = {
        allowUnfree = true;
      };
      nix = {
        optimise = {
          automatic = true;
        };
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          substituters = [
            "https://nix-community.cachix.org"
            "https://cache.nixos.org"
          ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          ];
          trusted-users = [
            "@nixbld"
            "root"
            "yadunut"
          ];
        };
      };
    };
  flake.modules.darwin.base =
    { ... }:
    {
      nixpkgs.config = {
        allowUnfree = true;
      };

    };
}
