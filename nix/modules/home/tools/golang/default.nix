{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.golang;
in {
  options.vlib.tools.golang = { enable = mkEnableOption "golang"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ go ]; };
}
