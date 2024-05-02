{ config, pkgs, lib, ... }:

with lib;
let cfg = config.vlib.cli-apps.tmux;
in {
  options.vlib.cli-apps.tmux = { enable = mkEnableOption "tmux"; };

  config = mkIf cfg.enable {
    vlib = {
      dotfiles = {
        enable = true;
        configFile = { "tmux-extra" = "tmux"; };
      };
    };

    programs.tmux = {
      enable = true;

      clock24 = true;

      historyLimit = 10000;

      plugins = with pkgs; [
        tmuxPlugins.vim-tmux-navigator
        tmuxPlugins.catppuccin
      ];

      tmuxp.enable = true;

      extraConfig = ''
        source-file ~/.config/tmux-extra/tmux.conf
      '';
    };
  };
}

