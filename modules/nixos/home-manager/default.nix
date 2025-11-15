{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.nut.home-manager;
in
{
  options.nut.home-manager = {
    enable = mkEnableOption "home-manager configuration";
    userImports = mkOption {
      type = types.listOf types.unspecified;
      default = [ ];
      description = "Additional imports for the yadunut user";
    };
  };

  config = mkIf cfg.enable {
    home-manager = {
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      users.yadunut.imports = cfg.userImports;
    };
  };
}

