{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.jq;
in {
  options.vlib.tools.jq = { enable = mkEnableOption "jq"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ jq ]; };
}
