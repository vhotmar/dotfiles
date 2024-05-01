{ config, lib, ... }:

with lib;
let cfg = config.vlib.suites.common;
in {
  options.vlib.suites.common = {
    enable = mkEnableOption "common suite";
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
