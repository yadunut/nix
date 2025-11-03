{
  _class,
  lib,
  config,
  inputs,
  ...
}:

let
  keys = import ../../../keys.nix;
  cfg = config.nut.users;
  nixosModule = {
    config = lib.mkIf cfg.enable {
      # Enable Home Manager for NixOS and define the user
      home-manager.useUserPackages = true;
      home-manager.users.yadunut = {
        imports = [ ./home.nix ];
        home.homeDirectory = lib.mkForce "/home/yadunut";
      };
    };
  };
  darwinModule = {
    config = lib.mkIf cfg.enable {
      users.users."yadunut" = {
        openssh.authorizedKeys.keys = [ keys.yadunut ];
      };
      users.users."root" = {
        openssh.authorizedKeys.keys = [ keys.yadunut ];
      };
      home-manager.useUserPackages = true;
      home-manager.users.yadunut = {
        imports = [ ./home.nix ];
        home.homeDirectory = lib.mkForce "/Users/yadunut";
      };
    };
  };
in
{
  imports = [
    # Import the correct Home Manager module for the current platform
    (
      if _class == "darwin" then
        inputs.home-manager.darwinModules.home-manager
      else
        inputs.home-manager.nixosModules.home-manager
    )
    (lib.optionalAttrs (_class == "nixos") nixosModule)
    (lib.optionalAttrs (_class == "darwin") darwinModule)
  ];
  options.nut.users = {
    enable = lib.mkEnableOption "user setup";
  };
}
