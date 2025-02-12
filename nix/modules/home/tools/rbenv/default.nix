{ config, pkgs, lib, ... }:

with lib;
let cfg = config.vlib.tools.rbenv;
in {
  options.vlib.tools.rbenv = with types; { enable = mkEnableOption "rbenv"; };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ libyaml ];

    programs.rbenv = {
      enable = true;
      enableFishIntegration = true;

      plugins = [{
        name = "ruby-build";
        src = pkgs.fetchFromGitHub {
          owner = "rbenv";
          repo = "ruby-build";
          rev = "v20250130";
          hash = "sha256-PrWp4AXstiCPq/nxHjbpVbuhEd6fzExIE7tfl28bDX8=";
        };
      }];
    };
  };
}

