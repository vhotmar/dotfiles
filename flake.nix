{
  description = "vhotmar's dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code-overlay = {
      url = "github:ryoppippi/claude-code-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util = {
      url = "github:hraban/mac-app-util";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      determinate,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      fenix,
      claude-code-overlay,
      mac-app-util,
      ...
    }@inputs:
    let
      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowBroken = true;
          };
          overlays = import ./overlays { inherit inputs; };
        };

      mkDarwin =
        {
          host,
          extraModules ? [ ],
        }:
        nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          pkgs = mkPkgs "aarch64-darwin";
          specialArgs = { inherit inputs host; };
          modules = [
            ./darwin/configuration.nix
            determinate.darwinModules.default
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                user = host.username;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                };
                mutableTaps = false;
              };
            }
            mac-app-util.darwinModules.default
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit host; };
                sharedModules = [ mac-app-util.homeManagerModules.default ];
                users.${host.username} = import ./home-manager/darwin.nix;
              };
            }
          ]
          ++ extraModules;
        };
    in
    {
      darwinConfigurations."work" = mkDarwin {
        host = {
          profile = "work";
          username = "vhotmar";
          email = "vojtech.hotmar@pm.me";
        };
        extraModules = [ ./darwin/work.nix ];
      };

      darwinConfigurations."home" = mkDarwin {
        host = {
          profile = "home";
          username = "vhotmar";
          email = "vojtech.hotmar@pm.me";
        };
        extraModules = [ ./darwin/home.nix ];
      };

      homeConfigurations."vhotmar@unix-server" = home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs "x86_64-linux";
        extraSpecialArgs.host = {
          profile = "vhotmar@unix-server";
          username = "vhotmar";
          email = "vojtech.hotmar@pm.me";
        };
        modules = [ ./home-manager/linux.nix ];
      };

      homeConfigurations."vhotmar@lima" = home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs "aarch64-linux";
        extraSpecialArgs.host = {
          profile = "vhotmar@lima";
          username = "vhotmar";
          email = "vojtech.hotmar@pm.me";
        };
        modules = [ ./home-manager/lima.nix ];
      };
    };
}
