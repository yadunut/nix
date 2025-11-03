{
  inputs.clan-core.url = "https://git.yadunut.dev/yadunut/clan-core/archive/main.tar.gz";
  inputs.nixpkgs.follows = "clan-core/nixpkgs";
  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "clan-core/nixpkgs";
  };
  inputs.nixvim = {
    url = "github:nix-community/nixvim";
    inputs.nixpkgs.follows = "clan-core/nixpkgs";
  };

  outputs =
    {
      self,
      clan-core,
      nixpkgs,
      ...
    }@inputs:
    let
      # Usage see: https://docs.clan.lol
      clan = clan-core.lib.clan {
        inherit self;
        imports = [ ./clan.nix ];
        specialArgs = { inherit inputs; };
      };
    in
    {
      inherit (clan.config)
        nixosConfigurations
        nixosModules
        darwinConfigurations
        clanInternals
        ;
      clan = clan.config;
      # Add the Clan cli tool to the dev shell.
      # Use "nix develop" to enter the dev shell.
      devShells =
        nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
            "aarch64-darwin"
            "x86_64-darwin"
          ]
          (
            system:

            let
              pkgs = import nixpkgs { inherit system; };
            in
            {
              default = clan-core.inputs.nixpkgs.legacyPackages.${system}.mkShell {
                packages = [
                  clan-core.packages.${system}.clan-cli
                  pkgs.nil
                ];
              };
            }
          );
    };
}
