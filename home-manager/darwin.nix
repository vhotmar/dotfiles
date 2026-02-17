# home-manager/darwin.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [ ./common.nix ];

  home.username = lib.mkForce "vhotmar";
  home.homeDirectory = lib.mkForce "/Users/vhotmar";

  home.packages = with pkgs; [
    # ── macOS-only packages ───────────────────────────────────────────────────
    pngpaste
    powershell
    kdoctor
    openconnect
    vpn-slice-vhotmar
    oauth2c
    rust-script
    rqbit
    # azure-cli  # disabled in current config
    # ollama     # disabled in current config
  ];

  programs.rbenv = {
    enable = true;
    enableFishIntegration = true;

    plugins = [
      {
        name = "ruby-build";
        src = pkgs.fetchFromGitHub {
          owner = "rbenv";
          repo = "ruby-build";
          rev = "v20250130";
          hash = "sha256-PrWp4AXstiCPq/nxHjbpVbuhEd6fzExIE7tfl28bDX8=";
        };
      }
    ];
  };

}
