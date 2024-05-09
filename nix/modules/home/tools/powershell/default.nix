{ config, lib, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.powershell;
in {
  options.vlib.tools.powershell = { enable = mkEnableOption "powershell"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ powershell ]; };
}

