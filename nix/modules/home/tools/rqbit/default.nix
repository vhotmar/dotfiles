{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.rqbit;
in {
  options.vlib.tools.rqbit = { enable = mkEnableOption "rqbit"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ rqbit ]; };
}
