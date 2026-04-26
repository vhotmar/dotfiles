# home-manager/desktop.nix
# Display-dependent config. Imported only on hosts with a GUI (i.e. not
# headless servers or Lima VMs).
{
  config,
  pkgs,
  lib,
  ...
}:

let
  mkSymlink =
    path:
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/main/dotfiles/.config/${path}";
in
{
  home.packages = with pkgs; [
    ueberzugpp

    # Thin wrapper so `alacritty-kdev` is on PATH for non-login-shell
    # callers (Alfred, launchd, etc). The real script stays in
    # .local/bin so edits don't require a home-manager rebuild.
    (writeShellScriptBin "alacritty-kdev" ''
      exec "${config.home.homeDirectory}/main/dotfiles/.local/bin/alacritty-kdev" "$@"
    '')
  ];

  programs.alacritty.enable = true;

  xdg.configFile."alacritty".source = mkSymlink "alacritty";
}
