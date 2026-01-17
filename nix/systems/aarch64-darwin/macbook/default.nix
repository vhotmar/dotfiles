{ pkgs, ... }:

{
  vlib = { suites = { common = { enable = true; }; }; };

  environment = { shells = with pkgs; [ bash zsh fish ]; };

  system.stateVersion = 6;

  system.primaryUser = "vhotmar";
}
