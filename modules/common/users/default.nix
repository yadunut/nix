{
  _class,
  lib,
  config,
  ...
}:

let
  keys = import ../../../keys.nix;
  cfg = config.nut.users;
  nixosModule = { };
  darwinModule = {
    config = lib.mkIf cfg.enable {
      # Darwin user configuration
      users.users."yadunut" = {
        home = "/Users/yadunut";
        openssh.authorizedKeys.keys = [ keys.user.yadunut ];
      };
      users.users."root" = {
        openssh.authorizedKeys.keys = [ keys.user.yadunut ];
      };
    };
  };
in
{
  imports = [
    (lib.optionalAttrs (_class == "nixos") nixosModule)
    (lib.optionalAttrs (_class == "darwin") darwinModule)
  ];
  options.nut.users = {
    enable = lib.mkEnableOption "user setup";
  };
}
