{ config, lib, pkgs, ... }:

with lib;
let cfg = config.vlib.cli-apps.sesh;
in {
  options.vlib.cli-apps.sesh = { enable = mkEnableOption "sesh"; };

  config = mkIf cfg.enable {
    vlib = {
      dotfiles = {
        enable = true;
        configFile = { "sesh" = "sesh"; };
      };
    };

    home.packages = with pkgs; [ sesh ];
  };
}

