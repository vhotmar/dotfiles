{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.vlib.tools.starship;
  flavour = "frappe";
in {
  options.vlib.tools.starship = with types; {
    enable = mkEnableOption "Starship";
  };

  config = mkIf cfg.enable {
    programs = {
      starship = {
        enable = true;

        settings = {
          palette = "catppuccin_${flavour}";
        } // builtins.fromTOML (builtins.readFile ./nerd-font.toml)
          // builtins.fromTOML (builtins.readFile ./prompt.toml)
          // builtins.fromTOML (builtins.readFile (pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "starship";
            rev = "5629d23";
            sha256 = "nsRuxQFKbQkyEI4TXgvAjcroVdG+heKX5Pauq/4Ota0=";
          } + /palettes/${flavour}.toml));
      };
    };
  };
}
