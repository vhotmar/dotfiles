{ config, lib, ... }:

with lib;
let cfg = config.vlib.cli-apps.lazygit;
in {
  options.vlib.cli-apps.lazygit = { enable = mkEnableOption "lazygit"; };

  config = mkIf cfg.enable {
    vlib = {
      dotfiles = {
        enable = true;
        configFile = { "lazygit" = "lazygit"; };
      };
    };

    programs.lazygit = { enable = true; };
  };
}

