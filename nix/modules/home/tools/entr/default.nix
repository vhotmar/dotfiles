{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.entr;
in {
  options.vlib.tools.entr = { enable = mkEnableOption "entr"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ entr ]; };
}
