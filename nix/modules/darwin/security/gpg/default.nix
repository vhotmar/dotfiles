{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.security.gpg;

in {
  options.vlib.security.gpg = { enable = mkEnableOption "GPG"; };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ gnupg ];

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}

