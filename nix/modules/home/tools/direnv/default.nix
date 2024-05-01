{ options, config, lib, pkgs, ... }:

let cfg = config.vlib.tools.direnv;
in {
  options.vlib.tools.direnv = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether or not to enable direnv.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv = { enable = true; };
    };
  };
}
