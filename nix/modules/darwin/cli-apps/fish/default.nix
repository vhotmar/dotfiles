{ options, config, lib, pkgs, ... }:

let cfg = config.vlib.cli-apps.fish;
in {
  options.vlib.cli-apps.fish = { enable = lib.mkEnableOption "Fish Shell"; };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;
      useBabelfish = true;
      babelfishPackage = pkgs.babelfish;
    };
  };
}
