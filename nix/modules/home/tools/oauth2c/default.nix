{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.oauth2c;
in {
  options.vlib.tools.oauth2c = { enable = mkEnableOption "oauth2c"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ oauth2c ]; };
}
