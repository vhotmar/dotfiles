{ config, pkgs, lib, ... }:

with lib;
let cfg = config.vlib.tools.vpn;
in {
  options.vlib.tools.vpn = { enable = mkEnableOption "vpn"; };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ openconnect vpn-slice-vhotmar ];
  };
}

