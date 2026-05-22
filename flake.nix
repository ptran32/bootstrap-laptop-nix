{
  description = "Declarative macOS (and optional Linux) laptop bootstrap";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }@inputs:
    let
      username = "patricetran";
    in {
      darwinConfigurations."patricetran-mac" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs username; };
        modules = [
          ./darwin/default.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Back up existing dotfiles (e.g. Cursor settings.json) on first activation.
            home-manager.backupFileExtension = "hm-bak";
            home-manager.users.${username} = import ./home;
            home-manager.extraSpecialArgs = { inherit inputs username; };
          }
        ];
      };

      darwinConfigurations."patricetran-mac-intel" = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        specialArgs = { inherit inputs username; };
        modules = [
          ./darwin/default.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Back up existing dotfiles (e.g. Cursor settings.json) on first activation.
            home-manager.backupFileExtension = "hm-bak";
            home-manager.users.${username} = import ./home;
            home-manager.extraSpecialArgs = { inherit inputs username; };
          }
        ];
      };
    };
}
