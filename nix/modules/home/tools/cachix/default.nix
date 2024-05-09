{ config, lib, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.cachix;
in {
  options.vlib.tools.cachix = { enable = mkEnableOption "cachix"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ cachix ]; };
}

