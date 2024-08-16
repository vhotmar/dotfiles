{ config, pkgs, lib, ... }:

with lib;
let cfg = config.vlib.tools.python;
in {
  options.vlib.tools.python = with types; {
    enable = mkEnableOption "python";

    package = mkOption {
      type = package;
      default = (pkgs.python3.withPackages
        (python-pkgs: [ python-pkgs.setuptools python-pkgs.distutils-extra ]));
      description = "The python package to use";
    };
  };

  config = mkIf cfg.enable { home.packages = [ cfg.package ]; };
}
