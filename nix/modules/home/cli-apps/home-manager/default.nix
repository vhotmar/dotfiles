{ lib, config, ... }:

let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.vlib.cli-apps.home-manager;
in {
  options.vlib.cli-apps.home-manager = {
    enable = mkEnableOption "home-manager";
  };

  config = mkIf cfg.enable { programs.home-manager = { enable = true; }; };
}
