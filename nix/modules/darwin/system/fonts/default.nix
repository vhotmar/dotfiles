{ config, pkgs, lib, ... }:

with lib;
let cfg = config.vlib.system.fonts;
in {
  options.vlib.system.fonts = with types; {
    enable = mkEnableOption "Whether or not to manage fonts.";

    fonts = mkOption {
      type = listOf package;
      default = [ ];
      description = "Custom font packages to install.";
    };
  };

  config = mkIf cfg.enable {
    environment.variables = {
      # Enable icons in tooling since we have nerdfonts.
      LOG_ICONS = "true";
    };

    fonts = {
      packages = with pkgs;
        [
          jetbrains-mono
          iosevka-bin
          lato
          fira-code
          fira-code-symbols
          julia-mono
          noto-fonts
          noto-fonts-emoji
          (nerdfonts.override { fonts = [ "FiraCode" "Iosevka" ]; })
        ] ++ cfg.fonts;
    };
  };
}
