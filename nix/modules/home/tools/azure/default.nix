{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.azure;
in {
  options.vlib.tools.azure = { enable = mkEnableOption "azure"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ azure-cli ]; };
}
