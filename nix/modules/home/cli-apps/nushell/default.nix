{ lib, config, ... }:

with lib;
let cfg = config.vlib.cli-apps.nushell;
in {
  options.vlib.cli-apps.nushell = { enable = mkEnableOption "nushell"; };

  config = mkIf cfg.enable { programs = { nushell = { enable = true; }; }; };
}
