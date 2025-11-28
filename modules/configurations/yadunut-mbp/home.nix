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
