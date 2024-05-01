{ lib, config, ... }:

with lib;
let cfg = config.vlib.tools.starship;
in {
  options.vlib.tools.starship = with types; {
    enable = mkEnableOption "Starship";
  };

  config = mkIf cfg.enable {
    programs = {
      starship = {
        enable = true;

        settings = builtins.fromTOML (builtins.readFile ./nerd-font.toml)
          // builtins.fromTOML (builtins.readFile ./prompt.toml);
      };
    };
  };
}
