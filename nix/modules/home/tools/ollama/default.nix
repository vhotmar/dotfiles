{ config, pkgs, lib, inputs, system, ... }:

with lib;
let cfg = config.vlib.tools.ollama;
in {
  options.vlib.tools.ollama = with types; { enable = mkEnableOption "ollama"; };

  config = mkIf cfg.enable { home.packages = with pkgs; [ ollama ]; };
}

