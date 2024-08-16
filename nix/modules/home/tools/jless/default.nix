{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.jless;
in {
  options.vlib.tools.jless = { enable = mkEnableOption "jless"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ jless ]; };
}
