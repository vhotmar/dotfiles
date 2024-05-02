{ config, lib, ... }:

with lib;
let cfg = config.vlib.tools.ssh;
in {
  options.vlib.tools.ssh = { enable = mkEnableOption "ssh"; };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ sshpass ];
  };
}

