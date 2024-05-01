{ config, pkgs, lib, ... }:

with lib;
let cfg = config.vlib.tools.tmux;
in {
  options.vlib.tools.tmux = { enable = mkEnableOption "tmux"; };

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
        {
          plugin = tmuxPlugins.catppuccin;
          extraConfig = ''
            set -g @catppuccin_flavour 'mocha'
          '';
        }
      ];

      extraConfig = ''
        source-file ~/.config/tmux-extra/tmux.conf
      '';
    };
  };
}

