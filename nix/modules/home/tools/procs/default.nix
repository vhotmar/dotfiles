{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.procs;
in {
  options.vlib.tools.procs = { enable = mkEnableOption "procs"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ procs ]; };
}
