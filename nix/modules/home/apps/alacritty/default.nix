{ config, lib, ... }:
with lib;
let cfg = config.vlib.apps.alacritty;
in {
  options.vlib.apps.alacritty = { enable = mkEnableOption "alacritty"; };

  config = mkIf cfg.enable {
    vlib = {
      dotfiles = {
        enable = true;
        configFile = { "alacritty" = "alacritty"; };
      };
    };

    programs.alacritty = { enable = true; };
  };
}

