{ config, pkgs, lib, ... }:

with lib;
let cfg = config.vlib.tools.yazi;
in {
  options.vlib.tools.yazi = { enable = mkEnableOption "yazi"; };

  config = mkIf cfg.enable {
    vlib = {
      dotfiles = {
        enable = true;
        configFile = { "yazi" = "yazi"; };
      };
    };

    programs.yazi = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
    };
  };
}

