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
        packages = [
          pkgs.entr
          pkgs.jq
          pkgs.just
          pkgs.rsync
          pkgs.dive
          pkgs.ouch

          pkgs.nil
          pkgs.nixd

          pkgs.claude-code
          pkgs.codex
        ];
        stateVersion = "25.05";
      };

      nixpkgs.config.allowUnfree = true;
      programs.home-manager.enable = true;
    };
}
