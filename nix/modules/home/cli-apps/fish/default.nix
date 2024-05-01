{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.cli-apps.fish;
in {
  options.vlib.cli-apps.fish = { enable = mkEnableOption "Fish"; };

  config = mkIf cfg.enable {
    vlib = {
      tools = {
        grc = { enable = true; };
        fzf = { enable = true; };
        starship = { enable = true; };
      };
    };

    programs = {
      fish = {
        enable = true;

        shellAbbrs = {
          g = "git";
          v = "nvim";
        };

        plugins = [
          {
            name = "grc";
            src = pkgs.fishPlugins.grc.src;
          }
          {
            name = "fzf-fish";
            src = pkgs.fishPlugins.fzf-fish.src;
          }
          {
            name = "forgit";
            src = pkgs.fishPlugins.forgit.src;
          }
        ];
      };

    };
  };
}
