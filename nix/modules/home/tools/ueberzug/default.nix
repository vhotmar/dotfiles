{ config, lib, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.ueberzug;
in {
  options.vlib.tools.ueberzug = { enable = mkEnableOption "ueberzug"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ ueberzugpp ]; };
}

