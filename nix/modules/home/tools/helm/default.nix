{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.helm;
in {
  options.vlib.tools.helm = { enable = mkEnableOption "helm"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ kubernetes-helm ]; };
}
