{ config, ... }:

{
  vlib = {
    user = {
      enable = true;
      name = config.snowfallorg.user.name;
    };

    suites = { common = { enable = true; }; };

    cli-apps = {
      home-manager = { enable = true; };
      lazygit = { enable = true; };
      sesh = { enable = true; };
    };

    tools = {
      gh = { enable = true; };
      devenv = { enable = true; };
      cachix = { enable = true; };
      yq = { enable = true; };
      gum = { enable = true; };
    };
  };

  home.sessionPath = [ "$HOME/main/bin" ];

  home.stateVersion = "23.11";
}
