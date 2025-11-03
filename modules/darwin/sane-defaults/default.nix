{
  self,
  lib,
  inputs,
  clan-core,
  specialArgs,
  config,
  options,
  _class,
  modulesPath,
  _prefix,
}@args:
let
  _ = builtins.trace "MODULE ARGS:\n${lib.generators.toPretty { } (builtins.attrNames args)}" null;
in
{
  system.defaults = {
    NSGlobalDomain = {
      InitialKeyRepeat = 10;
      KeyRepeat = 1;
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;
    };
    dock.autohide = true;
    dock.autohide-delay = 0.0;

  };

}
