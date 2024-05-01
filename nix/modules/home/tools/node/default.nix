{ config, pkgs, lib, ... }:

with lib;
let cfg = config.vlib.tools.node;
in {
  options.vlib.tools.node = with types; {
    enable = mkEnableOption "node";

    package = mkOption {
      type = package;
      default = pkgs.nodejs;
      description = "The node package to use";
    };
  };

  config = mkIf cfg.enable { home.packages = [ cfg.package ]; };
}
