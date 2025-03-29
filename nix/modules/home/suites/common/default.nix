{ config, lib, ... }:

with lib;
let cfg = config.vlib.suites.common;
in {
  options.vlib.suites.common = { enable = mkEnableOption "common suite"; };

  config = mkIf cfg.enable {
    programs.fish = { enable = true; };

    vlib = {
      cli-apps = {
        btop = { enable = true; };
        fish = { enable = true; };
        neovim = { enable = true; };
        tmux = { enable = true; };
        yazi = { enable = true; };
      };

      tools = {
        bat = { enable = true; };
        direnv = { enable = true; };
        fd = { enable = true; };
        jq = { enable = true; };
        git = { enable = true; };
        zoxide = { enable = true; };
        ssh = { enable = true; };
        clang = { enable = true; };
      };
    };
  };
}
