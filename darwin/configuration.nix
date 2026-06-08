# darwin/configuration.nix
{
  config,
  pkgs,
  lib,
  host,
  ...
}:

let
  username = host.username;
in
{
  imports = [
    ./brave.nix
  ];

  ids.gids.nixbld = 30000;

  determinateNix = {
    enable = true;

    customSettings = {
      trusted-users = [
        "root"
        username
      ];
      allowed-users = [
        "root"
        username
      ];

      extra-substituters = [
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
      ];

      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
    };
  };

  # Managed by nix-homebrew

  homebrew = {
    enable = true;

    taps = builtins.attrNames config.nix-homebrew.taps;

    casks = [
      "hammerspoon"
      "raycast"
      "rectangle"
    ];

    onActivation = {
      cleanup = "zap"; # remove casks/brews no longer declared here
      autoUpdate = true;
      upgrade = true;
    };
  };

  environment.systemPackages = with pkgs; [
    nixfmt
    nix-index
    nix-prefetch-git
    gnupg
    git
  ];

  environment.shells = with pkgs; [
    bash
    zsh
    fish
  ];

  environment.variables = {
    LOG_ICONS = "true";
  };

  fonts.packages = with pkgs; [
    jetbrains-mono
    iosevka-bin
    lato
    fira-code
    fira-code-symbols
    julia-mono
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.fira-code
    nerd-fonts.iosevka
  ];

  programs.fish = {
    enable = true;
    useBabelfish = true;
    babelfishPackage = pkgs.babelfish;

    # Fix PATH ordering - add per-user profile and nix paths to fish_user_paths
    # See: https://github.com/LnL7/nix-darwin/issues/122
    shellInit = ''
      for p in /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin
        if not contains $p $fish_user_paths
          set -g fish_user_paths $p $fish_user_paths
        end
      end
    '';
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  launchd.user.agents.yknotify = {
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/yknotify.out";
      StandardErrorPath = "/tmp/yknotify.err";
    };
    script = ''
      LAST_NTFY=0
      ${pkgs.yknotify}/bin/yknotify | while IFS= read -r line; do
        NOW=$(date +%s)
        if [ "$NOW" -le $((LAST_NTFY + 2)) ]; then
          continue
        fi
        LAST_NTFY=$NOW
        msg=$(echo "$line" | ${pkgs.jq}/bin/jq -r '.type')
        ${pkgs.terminal-notifier}/bin/terminal-notifier \
          -title yknotify -message "$msg" -sound Submarine
      done
    '';
  };

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  system.stateVersion = 6;
  system.primaryUser = username;

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  system.defaults.CustomUserPreferences = {
    "org.hammerspoon.Hammerspoon" = {
      MJConfigFile = "~/.config/hammerspoon/init.lua";
    };
  };

  local.brave.extensions = {
    # Kagi Search for Chrome
    "cdglnehniifkbagbbombnjghhcihifij" = {
      installation_mode = "normal_installed";
      update_url = "https://clients2.google.com/service/update2/crx";
    };
  };
}
