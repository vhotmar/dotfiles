{
  description = "vhotmar's dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

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
    in
    {
      # ══════════════════════════════════════════════════════════════════════════
      # macOS (macbook)
      # ══════════════════════════════════════════════════════════════════════════
      darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        pkgs = mkPkgs "aarch64-darwin";
        modules = [
          ./darwin/configuration.nix
          mac-app-util.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [ mac-app-util.homeManagerModules.default ];
            home-manager.users.vhotmar = import ./home-manager/darwin.nix;
          }
        ];
      };

      # ══════════════════════════════════════════════════════════════════════════
      # Linux (unix-server) - standalone home-manager
      # ══════════════════════════════════════════════════════════════════════════
      homeConfigurations."vhotmar@unix-server" = home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs "x86_64-linux";
        modules = [ ./home-manager/linux.nix ];
      };

      # ══════════════════════════════════════════════════════════════════════════
      # Linux (Lima VM on aarch64-darwin host) - standalone home-manager
      # ══════════════════════════════════════════════════════════════════════════
      homeConfigurations."vhotmar@lima" = home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs "aarch64-linux";
        modules = [ ./home-manager/lima.nix ];
      };
    };
}
