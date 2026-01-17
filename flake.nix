{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";

    nixpkgs-darwin-stable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # nixpkgs-darwin-stable.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # snowfall-flake = {
    #   url = "github:snowfallorg/flake";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;

      channels-config = {
        allowUnfree = true;
        allowBroken = true;
      };

      src = ./nix;

      # overlays = with inputs; [ snowfall-flake.overlays."package/flake" ];

      snowfall = { namespace = "vlib"; };
    };
}
