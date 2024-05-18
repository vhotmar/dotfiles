{ config, lib, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.gum;
in {
  options.vlib.tools.gum = { enable = mkEnableOption "gum"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ gum ]; };
}

