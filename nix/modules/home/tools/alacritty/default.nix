{ config, pkgs, lib, ... }:
with lib;
let cfg = config.vlib.tools.alacritty;
in {
  options.vlib.tools.alacritty = { enable = mkEnableOption "alacritty"; };

  config = mkIf cfg.enable {
    vlib = {
      dotfiles = {
        enable = true;
        configFile = { "alacritty" = "alacritty"; };
      };
    };

    programs.alacritty = {
      enable = true;
    };
  };
}

