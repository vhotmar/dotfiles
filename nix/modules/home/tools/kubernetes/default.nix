{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.kubernetes;
in {
  options.vlib.tools.kubernetes = { enable = mkEnableOption "kubernetes"; };

  config =
    mkIf cfg.enable { home.packages = with pkgs; [ k9s kind kubectl fluxcd ]; };
}
