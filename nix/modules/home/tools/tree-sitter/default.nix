{ lib, config, pkgs, ... }:

with lib;
let cfg = config.vlib.tools.tree-sitter;
in {
  options.vlib.tools.tree-sitter = { enable = mkEnableOption "tree-sitter"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ tree-sitter ]; };
}
