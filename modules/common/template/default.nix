{
  _class,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.nut.template;
  nixosModule = mkIf cfg.enable { };
  darwinModule = mkIf cfg.enable { };
in
{
  imports = [
    (lib.optionalAttrs (_class == "nixos") nixosModule)
    (lib.optionalAttrs (_class == "darwin") darwinModule)
  ];
  options.nut.template = { };
}
