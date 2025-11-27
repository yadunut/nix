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
        packages = with pkgs; [
          entr
          jq
          just
          dive
          nil
          nixd
          claude-code
          codex
        ];
      };
    };
}
