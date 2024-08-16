{ config, pkgs, lib, ... }:

with lib;
let cfg = config.vlib.tools.bat;
in {
  options.vlib.tools.bat = with types; { enable = mkEnableOption "bat"; };

  config = mkIf cfg.enable {
    vlib = {
      dotfiles = {
        enable = true;
        configFile = { "bat" = "bat"; };
      };
    };
    programs.bat = {
      # From the source in home-manager, this will also rebuild the themes cache
      # but we do want to have our own configuraiton
      enable = true;
    };
  };
}

