{ config, lib, ... }:

with lib;
let cfg = config.vlib.tools.ripgrep;
in {
  options.vlib.tools.ripgrep = { enable = mkEnableOption "ripgrep"; };

  config = mkIf cfg.enable {
    programs.ripgrep = {
      enable = true;
      arguments = [ "--ignore-case" ];
    };
  };
}

