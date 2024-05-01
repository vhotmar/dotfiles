{ lib, config, ... }:

with lib;
let
  cfg = config.vlib.tools.git;
  user = config.vlib.user;
in {
  options.vlib.tools.git = with types; {
    enable = mkEnableOption {
      default = false;
      description = "Enable the Git tooling.";
    };

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
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;

      inherit (cfg) userName userEmail;

      extraConfig = {
        init = { defaultBranch = "main"; };
        pull = { rebase = true; };
        push = { autoSetupRemote = true; };
        core = { whitespace = "trailing-space,space-before-tab"; };
      };

      difftastic.enable = true;

      aliases = {
        a = "add";
        d = "diff";
        dc = "diff --cached";
        ds = "diff --staged";
        s = "status --short";
        st = "status";
        co = "checkout";
        l = "log --pretty=oneline -n 20 --graph --abbrev-commit";
      };
    };
  };
}
