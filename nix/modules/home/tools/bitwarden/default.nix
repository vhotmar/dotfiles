{ config, pkgs, lib, inputs, system, ... }:

with lib;
let
  cfg = config.vlib.tools.bitwarden;
  user = config.vlib.user;
in {
  options.vlib.tools.bitwarden = with types; {
    enable = mkEnableOption "bitwarden";

    email = mkOption {
      type = str;
      default = user.email;
      description = "The email to configure git with.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ bitwarden-cli python312Packages.keyring_24 ];
    programs.rbw = {
      # From the source in home-manager, this will also rebuild the themes cache
      # but we do want to have our own configuraiton
      enable = true;

      settings = {
        inherit (cfg) email;
        pinentry = pkgs.pinentry-tty;
      };
    };
  };
}

