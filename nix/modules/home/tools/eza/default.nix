{ config, pkgs, lib, ... }:
with lib;
let cfg = config.vlib.tools.eza;
in {
  options.vlib.tools.eza = with types; {
    enable = mkEnableOption "eza";

    package = mkOption {
      type = package;
      default = pkgs.eza;
      description = "The EZA package to use";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ cfg.package ];

    programs.fish.shellAbbrs = {
      l = "eza -al";
      ls = "eza -l";
      la = "eza -al";
      ll = "eza -l";
      lL = "eza -algiSH --git";
      lt = "eza -lT";
    };
  };
}
