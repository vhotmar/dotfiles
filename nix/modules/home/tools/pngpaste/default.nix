{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.pngpaste;
in {
  options.vlib.tools.pngpaste = { enable = mkEnableOption "pngpaste"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ pngpaste ]; };
}
