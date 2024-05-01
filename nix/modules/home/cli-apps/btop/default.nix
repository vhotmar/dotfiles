{ config, lib, ... }:

with lib;
let cfg = config.vlib.cli-apps.btop;
in {
  options.vlib.cli-apps.btop = { enable = mkEnableOption "btop"; };

  config = mkIf cfg.enable {
    vlib = {
      dotfiles = {
        enable = true;
        configFile = { "btop" = "btop"; };
      };
    };

    # This is not doing anything special - just installing btop
    programs.btop = { enable = true; };
  };
}

