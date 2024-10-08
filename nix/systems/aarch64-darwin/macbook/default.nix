{ pkgs, ... }:

{
  vlib = { suites = { common = { enable = true; }; }; };

  environment = {
    shells = with pkgs; [ bash zsh fish ];

    loginShell = pkgs.fish;
  };

  system.stateVersion = 5;
}
