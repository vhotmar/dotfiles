{ config, pkgs, lib, inputs, system, ... }:

with lib;
let cfg = config.vlib.tools.kdoctor;
in {
  options.vlib.tools.kdoctor = with types; {
    enable = mkEnableOption "kdoctor";
  };

  config = mkIf cfg.enable { home.packages = with pkgs; [ kdoctor ]; };
}

