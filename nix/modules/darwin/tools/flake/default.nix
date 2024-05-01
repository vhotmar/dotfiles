{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.flake;
in {
  options.vlib.tools.flake = { enable = mkEnableOption "Flake"; };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ snowfallorg.flake ];
  };
}
