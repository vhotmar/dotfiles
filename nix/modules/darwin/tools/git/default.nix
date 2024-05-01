{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.git;
in {
  options.vlib.tools.git = { enable = mkEnableOption "git"; };

  config = mkIf cfg.enable { environment.systemPackages = with pkgs; [ git ]; };
}

