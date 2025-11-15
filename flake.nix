{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    clan-core = {
      url = "https://git.yadunut.dev/yadunut/clan-core/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "dedupe_systems";
      inputs.flake-parts.follows = "flake-parts";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.systems.follows = "dedupe_systems";
      inputs.nuschtosSearch.follows = "dedupe_nuschtosSearch";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    dedupe_systems.url = "github:nix-systems/default";
    dedupe_flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "dedupe_systems";
    };
    dedupe_nuschtosSearch = {
      url = "github:NuschtOS/search";
      inputs.flake-utils.follows = "dedupe_flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      clan-core,
      nixpkgs,
      agenix,
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
          (system: {
            default = clan-core.inputs.nixpkgs.legacyPackages.${system}.mkShell {
              packages = [
                clan-core.packages.${system}.clan-cli
                agenix.packages.${system}.default
              ];
            };
          });
    };
}
