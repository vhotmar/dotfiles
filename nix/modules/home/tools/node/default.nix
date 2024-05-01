{ config, pkgs, lib, ... }:

with lib;
let cfg = config.vlib.tools.node;
in {
  options.vlib.tools.node = with types; {
    enable = mkEnableOption "NodeJS";

    package = mkOption {
      type = package;
      default = pkgs.nodejs;
      description = "The NodeJS package to use";
    };
  };

  config = mkIf cfg.enable { home.packages = with pkgs; [ cfg.package ]; };
}
