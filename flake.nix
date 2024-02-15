{
  description = "Home Manager configuration of username";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      system-manager,
      flake-utils,
      ...
    }@inputs:
    let
      username = "username";
      mkHomeConf = system: {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {
          inherit inputs;
        };

        modules = [ ./home.nix ];
      };
    in
    {
      # https://github.com/nix-community/home-manager/issues/3075
      homeConfigurations."${username}@archlinux" = home-manager.lib.homeManagerConfiguration (
        mkHomeConf "x86_64-linux"
      );
      homeConfigurations."${username}@macos" = home-manager.lib.homeManagerConfiguration (
        mkHomeConf "aarch64-darwin"
      );

      systemConfigs.default = system-manager.lib.makeSystemConfig { modules = [ ./system.nix ]; };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nix-tree
            sops
            update-nix-fetchgit
          ];
        };
      }
    );
}
