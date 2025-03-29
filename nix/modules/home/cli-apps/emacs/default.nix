{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.cli-apps.emacs;
in {
  options.vlib.cli-apps.emacs = { enable = mkEnableOption "emacs"; };

  config = mkIf cfg.enable {
    vlib = {
      dotfiles = {
        enable = true;
        configFile = { doom = "doom"; };
      };
    };

    home.packages = with pkgs; [ emacs30 ];

    home.mutableFile."${config.xdg.configHome}/emacs" = {
      url = "https://github.com/doomemacs/doomemacs";
      type = "git";
      extraArgs = [ "--depth" "1" ];
    };
  };
}
