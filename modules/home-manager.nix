{ inputs, ... }:
{
  flake.modules.darwin.home-manager =
    { ... }:
    {
      imports = [
        inputs.home-manager.darwinModules.home-manager
      ];
      home-manager = {
        useUserPackages = true;
      };
    };
  flake.modules.nixos.home-manager =
    { ... }:
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
      ];
      home-manager = {
        useUserPackages = true;
      };
    };
}
