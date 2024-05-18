{ config, lib, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.rust-script;
in {
  options.vlib.tools.rust-script = { enable = mkEnableOption "rust-script"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ rust-script ]; };
}

