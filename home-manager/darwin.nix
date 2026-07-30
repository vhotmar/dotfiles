# home-manager/darwin.nix
{
  config,
  pkgs,
  lib,
  host,
  ...
}:

{
  imports = [
    ./common.nix
    ./desktop.nix
    ./llm.nix
  ];

  home.username = lib.mkForce host.username;
  home.homeDirectory = lib.mkForce "/Users/${host.username}";

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
    yknotify
    terminal-notifier
    lima
    # azure-cli  # disabled in current config
    # ollama     # disabled in current config
  ];

  home.sessionVariables = {
    # The nix Rust toolchain has no libiconv in its linker path on darwin, so
    # any cdylib build fails with `ld: library not found for -liconv` (e.g.
    # parinfer-rust). Expose it globally so plain `cargo build` links.
    # See https://github.com/nix-community/home-manager/issues/3482
    LIBRARY_PATH = lib.makeLibraryPath [ pkgs.libiconv ];
  };

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
