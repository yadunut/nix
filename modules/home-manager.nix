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
}
