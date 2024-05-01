{ config, lib, ... }:

with lib;
let cfg = config.vlib.cli-apps.zellij;
in {
  options.vlib.cli-apps.zellij = { enable = mkEnableOption "zellij"; };

  config = mkIf cfg.enable {
    vlib = {
      dotfiles = {
        enable = true;
        configFile = { "zellij" = "zellij"; };
      };
    };

    home.sessionVariables = {
      ZELLIJ_AUTO_ATTACH = "true";
      ZELLIJ_AUTO_EXIT = "true";
    };

    programs.zellij = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}

