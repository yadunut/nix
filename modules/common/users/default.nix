{
  _class,
  lib,
  config,
  pkgs,
  ...
}:

let
  keys = import ../../../hosts.nix;
  cfg = config.nut.users;
  createUser = name: args: {
    programs.zsh.enable = true;
    users.users.${name} = {
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [ keys.user.yadunut ];
    }
    // args;
  };
  nixosModule = {
    config = lib.mkIf cfg.enable (
      lib.mkMerge [
        { users.mutableUsers = false; }
        (createUser "yadunut" {
          isNormalUser = true;
          hashedPassword = "$y$j9T$XR5JhClixWp8d626AsjPZ.$PdN77P4SRt/GuJ9jVovcTSOh6ySf9alSsflFJG8n2A.";
          extraGroups = [ "wheel" ];
        })
        (createUser "root" {
          hashedPassword = "$y$j9T$XR5JhClixWp8d626AsjPZ.$PdN77P4SRt/GuJ9jVovcTSOh6ySf9alSsflFJG8n2A.";
        })
      ]
    );
  };
  darwinModule = {
    config = lib.mkIf cfg.enable (
      lib.mkMerge [
        (createUser "yadunut" {
          home = "/Users/yadunut";
        })
        (createUser "root" { })
      ]
    );
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
