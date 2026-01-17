{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.vlib.tools.git;
  user = config.vlib.user;
in {
  options.vlib.tools.git = with types; {
    enable = mkEnableOption "git" // { enable = true; };

    userName = mkOption {
      type = str;
      default = user.fullName;
      description = "The name to configure git with.";
    };

    userEmail = mkOption {
      type = str;
      default = user.email;
      description = "The email to configure git with.";
    };

    signingKey = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ jujutsu ];

    programs.difftastic.enable = true;
    programs.difftastic.git.enable = true;

    programs.git = {
      enable = true;

      settings = {

        user = {
          email = cfg.userEmail;
          name = cfg.userName;
        };

        alias = {
          a = "add";
          d = "diff";
          dc = "diff --cached";
          ds = "diff --staged";
          s = "status --short";
          st = "status";
          co = "checkout";
          l = "log --pretty=oneline -n 20 --graph --abbrev-commit";
        };

        init = { defaultBranch = "main"; };
        pull = { rebase = true; };
        push = { autoSetupRemote = true; };
        core = { whitespace = "trailing-space,space-before-tab"; };
      };

      signing = {
        format = "ssh";
        signByDefault = cfg.signingKey != null;
        key = cfg.signingKey;
      };

    };
  };
}
