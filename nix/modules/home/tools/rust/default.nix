{ config, pkgs, lib, ... }:

with lib;
let cfg = config.vlib.tools.rust;
in {
  options.vlib.tools.rust = { enable = mkEnableOption "rust"; };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (fenix.complete.withComponents [
        "cargo"
        "clippy"
        "rust-src"
        "rustc"
        "rustfmt"
      ])
      rust-analyzer-nightly
    ];
  };
}

