{ ... }:
{
  flake.modules.homeManager.yadunut-mbp =
    { pkgs, ... }:
    let
      keys = import ../../../hosts.nix;
    in
    {
      nut = {
        git = {
          gpgProgram = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
          signingKey = keys.user.yadunut;
        };
      };
      home = {
        username = "yadunut";
        packages = with pkgs; [
          entr
          jq
          just
          rsync
          dive
          ouch

          nil
          nixd

          claude-code
          codex
        ];
        stateVersion = "25.05";
      };
    };
}
