{ config, pkgs, lib, ... }:
with lib;
let cfg = config.vlib.tools.gh;
in {
  options.vlib.tools.gh = { enable = mkEnableOption "gh"; };

  config = mkIf cfg.enable {
    programs.gh = { enable = true; };

    programs.gh-dash = { enable = true; };
  };
}

