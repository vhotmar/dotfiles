{ config, lib, ... }:

with lib;
let cfg = config.vlib.tools.fd;
in {
  options.vlib.tools.fd = { enable = mkEnableOption "fd"; };

  config = mkIf cfg.enable { programs.fd = { enable = true; }; };
}

