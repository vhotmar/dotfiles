{ config, pkgs, ... }:

{
  vlib = {
    user = {
      enable = true;
      name = config.snowfallorg.user.name;
    };

    suites = { common = { enable = true; }; };

    apps = { alacritty = { enable = true; }; };

    cli-apps = {
      emacs = { enable = false; };
      home-manager = { enable = true; };
      lazygit = { enable = true; };
      sesh = { enable = true; };
      nushell = { enable = false; };
    };

    tools = {
      powershell = { enable = true; };
      gh = { enable = true; };
      git = {
        signingKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkXgI1lA120aiO1HCysdk3YEihbYCKvbGpoA0etbJxu";
      };
      vpn = { enable = true; };
      devenv = { enable = true; };
      cachix = { enable = true; };
      yq = { enable = true; };
      gum = { enable = true; };
      rust-script = { enable = true; };
      entr = { enable = true; };
      dust = { enable = true; };
      procs = { enable = true; };
      jless = { enable = true; };
      oauth2c = { enable = true; };
      azure = { enable = false; };
      helm = { enable = true; };
      pngpaste = { enable = true; };
      golang = { enable = true; };
      bitwarden = { enable = true; };
      kubernetes = { enable = true; };
      python = { enable = true; };
      rqbit = { enable = true; };
      kdoctor = { enable = true; };
      rbenv = { enable = true; };
      ollama = { enable = false; };
    };
  };

  home.sessionPath = [ "$HOME/main/bin" ];

  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    claude-code
    opencode
    bun
    ast-grep
    github-copilot-cli
    proton-pass-cli
    jira-cli-go
  ];
}
