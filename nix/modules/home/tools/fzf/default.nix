{ config, lib, ... }:

with lib;
let cfg = config.vlib.tools.fzf;
in {
  options.vlib.tools.fzf = with types; { enable = mkEnableOption "fzf"; };

  config = mkIf cfg.enable {
    programs.fzf = {

      enable = true;

      fileWidgetOptions = [
        # Preview the contents of the selected file
        "--preview 'bat --color=always --plain {}'"
      ];

      changeDirWidgetOptions = [
        # Preview the contents of the selected directory
        "--preview 'eza -l --tree --level=2 --color=always {}'"
      ];
    };
  };
}

