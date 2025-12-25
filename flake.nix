{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    make-shell.url = "github:nicknovitski/make-shell";
    import-tree.url = "github:vic/import-tree";
    clan-core = {
      url = "https://github.com/yadunut/clan-core/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "dedupe_systems";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nix-darwin.follows = "nix-darwin";
      inputs.disko.follows = "disko";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
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
  };

  outputs =
    { flake-parts, ... }@inputs:
    let
      hosts = import ./hosts.nix;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;
      _module.args.hosts = hosts;
      imports = [ (inputs.import-tree ./modules) ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    };
}
