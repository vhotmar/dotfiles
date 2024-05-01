{ config, lib, ... }:

with lib;
let cfg = config.vlib.tools.direnv;
in {
  options.vlib.tools.direnv = { enable = mkEnableOption "direnv"; };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv = { enable = true; };
    };
  };
}
