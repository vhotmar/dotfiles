{ config, pkgs, lib, ... }:

with lib;
let cfg = config.vlib.tools.grc;
in {
  options.vlib.tools.grc = with types; {
    enable = mkEnableOption "grc";

    package = mkOption {
      type = package;
      default = pkgs.grc;
      description = "The GRC package to use";
    };
  };

  config = mkIf cfg.enable { home.packages = [ cfg.package ]; };
}
