{ config, lib, ... }:

with lib;
let cfg = config.vlib.cli-apps.yazi;
in {
  options.vlib.cli-apps.yazi = { enable = mkEnableOption "yazi"; };

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

