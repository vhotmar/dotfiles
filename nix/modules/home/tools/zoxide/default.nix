{ config, pkgs, lib, ... }:

with lib;
let cfg = config.vlib.tools.zoxide;
in {
  options.vlib.tools.zoxide = { enable = mkEnableOption "zoxide"; };

  config = mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}

