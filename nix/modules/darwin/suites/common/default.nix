{ options, config, lib, pkgs, ... }:

with lib;
let cfg = config.vlib.suites.common;
in {
  options.vlib.suites.common = with types; {
    enable = mkOption {
      type = bool;
      default = false;
      description = "Whether or not to enable common configuration.";
    };
  };

  config = mkIf cfg.enable {
    programs.fish = { enable = true; };

    vlib = {
      nix = { enable = true; };

      tools = {
        git = { enable = true; };
        flake = { enable = true; };
      };

      system = { fonts = { enable = true; }; };

      security = { gpg = { enable = true; }; };
    };
  };
}
