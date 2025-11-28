{ hosts, ... }:
{
  flake.modules.homeManager.penguin =
    { pkgs, ... }:
    let
      hosts = hosts;
    in
    {
      nut = {
        git = {
          signingKey = hosts.user.penguin-yadunut;
        };
      };
      home.packages = with pkgs; [
        dive
        just
      ];

      services.syncthing = {
        enable = true;
        guiAddress = "0.0.0.0:8384";
        settings = {
          options = {
            urAccepted = -1;
          };
          devices = {
            "yadunut-mbp" = {
              id = "2KL36Z3-DZSQKEY-H26OOAZ-7PY7U3B-X53GXKH-LILC7KW-7EWXNCD-CMMUJAS";
              name = "yadunut-mbp";
            };
            "yadunut-iPhone" = {
              id = "3B4KGXN-IG43N4R-WVMQW4N-QC2OJ4C-PZSKLQI-ZCDBOP5-RLDXYH7-FQK3JAH";
              name = "yadunut-iPhone";
            };
          };
          folders = {
            "Obsidian" = {
              id = "mxzrk-t3afy";
              path = "~/Obsidian";
              devices = [
                "yadunut-mbp"
                "yadunut-iPhone"
              ];
            };
          };

        };
      };
    };
}
