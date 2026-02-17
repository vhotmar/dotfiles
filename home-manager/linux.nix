# home-manager/linux.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [ ./common.nix ];

  home.username = "vhotmar";
  home.homeDirectory = "/home/vhotmar";

  # Linux uses fewer packages - just the common suite
  # Add linux-specific packages here as needed
  home.packages = with pkgs; [
    # ── Linux-only packages ───────────────────────────────────────────────────
  ];
}
