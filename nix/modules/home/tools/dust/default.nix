{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.dust;
in {
  options.vlib.tools.dust = { enable = mkEnableOption "dust"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ du-dust ]; };
}
