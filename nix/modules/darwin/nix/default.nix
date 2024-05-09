{ config, pkgs, lib, ... }:

let cfg = config.vlib.nix;
in {
  options.vlib.nix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether or not to manage nix configuration.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nixVersions.git;
      description = "Which nix package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nixfmt-classic
      nix-index
      nix-prefetch-git
    ];

    nix = let users = [ "root" config.vlib.user.name ];
    in {
      package = cfg.package;

      settings = {
        experimental-features = "nix-command flakes";

        trusted-users = users;
        allowed-users = users;
      };

      gc = {
        automatic = true;
        interval = { Day = 7; };
        options = "--delete-older-than 30d";
        user = config.vlib.user.name;
      };

      # flake-utils-plus
      generateRegistryFromInputs = true;
      generateNixPathFromInputs = true;
      linkInputs = true;
    };
  };
}
