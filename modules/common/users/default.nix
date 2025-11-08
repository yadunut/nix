{
  _class,
  lib,
  config,
  pkgs,
  ...
}:

let
  keys = import ../../../keys.nix;
  cfg = config.nut.users;
  createUser = name: args: {
    users.users.${name} = {
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [ keys.user.yadunut ];
    }
    // args;
  };
  nixosModule = {
    config = lib.mkIf cfg.enable (
      lib.mkMerge [
        (createUser "yadunut" {
          isNormalUser = true;
          hashedPassword = "$y$j9T$9ATrmrhedhb.mAZ4//PiN/$OStCOaJHt3kPA63imTG3zLMWCSLoWCUph5O6jl5mcZ.";
          extraGroups = [ "wheel" ];
        })
        (createUser "root" {
          hashedPassword = "$6$xa/mFg4OxIbb8XiQ$S2RVyCKcLaKHymFs48u8vj1dv.mQdxt.BQoucJsr8wfcHayXwKfD0C2NIOYY5AEPR9zgnMvFp8d8STKe6wMGR/";
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
