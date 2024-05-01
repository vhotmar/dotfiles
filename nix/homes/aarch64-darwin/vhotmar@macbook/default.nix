{ lib, pkgs, config, osConfig ? { }, format ? "unknown", ... }:

{
  vlib = {
    user = {
      enable = true;
      name = config.snowfallorg.user.name;
    };

    cli-apps = {
      fish = { enable = true; };
      neovim = { enable = true; };
      home-manager = { enable = true; };
      emacs = { enable = true; };
    };

    tools = {
      git = { enable = true; };
      direnv = { enable = true; };
      bat = { enable = true; };
      fd = { enable = true; };
      vpn = { enable = true; };
      gh = { enable = true; };
      btop = { enable = true; };
      # zellij = { enable = true; };
      tmux = { enable = true; };
      # kitty = { enable = true; };
      alacritty = { enable = true; };
      lazygit = { enable = true; };
      yazi = { enable = true; };
      zoxide = { enable = true; };
      jq = { enable = true; };
    };
  };

  home.sessionPath = [ "$HOME/bin" ];

  home.stateVersion = "23.11";
}
