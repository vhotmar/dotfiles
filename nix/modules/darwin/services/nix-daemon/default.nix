{ lib, config, ... }:

with lib;
let cfg = config.vlib.services.nix-daemon;
in {
  options.vlib.services.nix-daemon = {
    enable = mkEnableOption "Nix daemon." // { default = true; };
  };

  config = (mkIf cfg.enable { services.nix-daemon = { enable = true; }; });
}
