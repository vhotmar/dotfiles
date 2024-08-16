{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.wget;
in {
  options.vlib.tools.wget = { enable = mkEnableOption "wget"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ wget ]; };
}
