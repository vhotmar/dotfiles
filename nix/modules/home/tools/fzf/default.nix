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

      defaultOptions = [ "--ansi" "--no-separator" ];

      fileWidgetOptions = [
        # Preview the contents of the selected file
        "--walker-skip .git,node_modules,target"
        "--preview 'bat --color=always --plain {}'"
        "--bind 'ctrl-/:change-preview-window(down|hidden|)'"
      ];

      changeDirWidgetOptions = [
        # Preview the contents of the selected directory
        "--walker-skip .git,node_modules,target"
        "--preview 'eza -l --tree --level=2 --color=always {}'"
      ];

      historyWidgetOptions = [
        "--preview 'echo {}' --preview-window up:3:hidden:wrap"
        "--bind 'ctrl-/:toggle-preview'"
        "--bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'"
        "--color header:italic"
        "--header 'Press CTRL-Y to copy command into clipboard'"
      ];

    };
  };
}

