{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.clang;
in {
  options.vlib.tools.clang = { enable = mkEnableOption "CLang"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ clang ]; };
}
