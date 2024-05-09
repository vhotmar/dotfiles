{ config, lib, ... }:

with lib;
let cfg = config.vlib.tools.fzf;
in {
  options.vlib.tools.fzf = with types; { enable = mkEnableOption "fzf"; };

  config = mkIf cfg.enable {
    programs.fzf = {

      enable = true;

      # https://github.com/catppuccin/fzf
      colors = {
        "bg+" = "#414559";
        bg = "#303446";
        spinner = "#f2d5cf";
        hl = "#e78284";
        fg = "#c6d0f5";
        header = "#e78284";
        info = "#ca9ee6";
        pointer = "#f2d5cf";
        marker = "#f2d5cf";
        "fg+" = "#c6d0f5";
        prompt = "#ca9ee6";
        "hl+" = "#e78284";
      };

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

