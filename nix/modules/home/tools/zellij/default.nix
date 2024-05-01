{ config, pkgs, lib, ... }:

with lib;
let cfg = config.vlib.tools.zellij;
in {
  options.vlib.tools.zellij = { enable = mkEnableOption "zellij"; };

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

