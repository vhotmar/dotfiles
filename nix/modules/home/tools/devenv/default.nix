{ config, lib, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.devenv;
in {
  options.vlib.tools.devenv = { enable = mkEnableOption "devenv"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ devenv ]; };
}

