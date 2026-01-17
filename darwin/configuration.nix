# darwin/configuration.nix
{ config, pkgs, lib, ... }:

let
  username = "vhotmar";
in
{
  # ══════════════════════════════════════════════════════════════════════════════
  # NIX SETTINGS
  # ══════════════════════════════════════════════════════════════════════════════

  ids.gids.nixbld = 30000;

  nix = {
    enable = true;
    package = pkgs.nixVersions.latest;

    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "root" username ];
      allowed-users = [ "root" username ];
    };

    gc = {
      automatic = true;
      interval = { Day = 7; };
      options = "--delete-older-than 30d";
    };
  };

  # ══════════════════════════════════════════════════════════════════════════════
  # SYSTEM PACKAGES
  # ══════════════════════════════════════════════════════════════════════════════

  environment.systemPackages = with pkgs; [
    nixfmt-rfc-style
    nix-index
    nix-prefetch-git
    gnupg
    git
  ];

  environment.shells = with pkgs; [ bash zsh fish ];

  # ══════════════════════════════════════════════════════════════════════════════
  # FONTS
  # ══════════════════════════════════════════════════════════════════════════════

  environment.variables = { LOG_ICONS = "true"; };

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

  # ══════════════════════════════════════════════════════════════════════════════
  # PROGRAMS
  # ══════════════════════════════════════════════════════════════════════════════

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

  # ══════════════════════════════════════════════════════════════════════════════
  # USERS
  # ══════════════════════════════════════════════════════════════════════════════

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # ══════════════════════════════════════════════════════════════════════════════
  # SYSTEM
  # ══════════════════════════════════════════════════════════════════════════════

  system.stateVersion = 6;
  system.primaryUser = username;
}
