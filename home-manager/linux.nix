# home-manager/linux.nix
{
  config,
  pkgs,
  lib,
  host,
  ...
}:

{
  imports = [ ./common.nix ];

  home.username = host.username;
  home.homeDirectory = "/home/${host.username}";

  # Linux uses fewer packages - just the common suite
  # Add linux-specific packages here as needed
  home.packages = with pkgs; [
    # ── Linux-only packages ───────────────────────────────────────────────────
  ];
}
