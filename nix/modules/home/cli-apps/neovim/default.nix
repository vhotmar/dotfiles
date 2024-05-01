{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.cli-apps.neovim;
in {
  options.vlib.cli-apps.neovim = { enable = mkEnableOption "Neovim"; };

  config = mkIf cfg.enable {
    vlib = {
      dotfiles = {
        enable = true;
        configFile = { "nvim/lua" = "nvim/lua"; };
      };
      tools = {
        rust = { enable = true; };
        node = { enable = true; };
        fzf = { enable = true; };
        eza = { enable = true; };
        grc = { enable = true; };
        ripgrep = { enable = true; };
      };
    };

    programs.neovim = {
      enable = true;

      vimAlias = true;
      viAlias = true;
      vimdiffAlias = true;

      defaultEditor = true;

      plugins = with pkgs.vimPlugins; [ lazy-nvim ];

      extraLuaConfig = ''
        require('main')
      '';
    };
  };
}
