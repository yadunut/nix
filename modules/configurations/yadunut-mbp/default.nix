{
  config,
  ...
}:
{
  configurations.darwin.yadunut-mbp.module = {
    imports = with config.flake.modules.darwin; [
      base
      home-manager
    ];
    home-manager = {
      users.yadunut.imports = with config.flake.modules.homeManager; [
        nixvim
        base
        yadunut-mbp
      ];
    };

    nixpkgs.hostPlatform = "aarch64-darwin";
    nix.enable = false; # since we're using nix darwin and determinate nix
    system.stateVersion = 6;
  };
}
