{ hosts, ... }:
{
  flake.modules.homeManager.yadunut-mbp =
    { pkgs, ... }:
    {
      nut = {
        git = {
          gpgProgram = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
          signingKey = hosts.user.yadunut;
        };
      };
      home = {
        packages = with pkgs; [
          claude-code
          codex
          dive
          entr
          jjui
          jq
          just
          nil
          nixd
        ];
      };
    };
}
