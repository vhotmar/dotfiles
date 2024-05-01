{ config, lib, ... }:

with lib;
let cfg = config.vlib.apps.kitty;
in {
  options.vlib.apps.kitty = { enable = mkEnableOption "kitty"; };

  config = mkIf cfg.enable {
    vlib = {
      dotfiles = {
        enable = true;
        configFile = { "kitty-extra" = "kitty"; };
      };
    };

    programs.kitty = {
      enable = true;
      theme = "Doom One";
      font = {
        name = "Iosevka Term";
        size = 12;
      };
      extraConfig = ''
        include ~/.config/kitty-extra/kitty.conf
      '';
    };
  };
}

