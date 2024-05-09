{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.yq;
in {
  options.vlib.tools.yq = { enable = mkEnableOption "yq"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ yq-go ]; };
}
