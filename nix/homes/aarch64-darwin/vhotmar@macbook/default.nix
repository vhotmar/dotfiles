{ config, ... }:

{
  vlib = {
    user = {
      enable = true;
      name = config.snowfallorg.user.name;
    };

    suites = { common = { enable = true; }; };

    apps = { alacritty = { enable = true; }; };

    cli-apps = {
      emacs = { enable = true; };
      home-manager = { enable = true; };
      lazygit = { enable = true; };
    };

    tools = {
      gh = { enable = true; };
      vpn = { enable = true; };
      devenv = { enable = true; };
      cachix = { enable = true; };
    };
  };

  home.sessionPath = [ "$HOME/main/bin" ];

  home.stateVersion = "23.11";
}
