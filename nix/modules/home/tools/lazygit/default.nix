{ config, pkgs, lib, ... }:

with lib;
let cfg = config.vlib.tools.lazygit;
in {
  options.vlib.tools.lazygit = { enable = mkEnableOption "lazygit"; };

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

