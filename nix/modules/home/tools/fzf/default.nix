{ config, lib, ... }:

with lib;
let cfg = config.vlib.tools.fzf;
in {
  options.vlib.tools.fzf = with types; { enable = mkEnableOption "fzf"; };

  config = mkIf cfg.enable {
    programs.fzf = {

      enable = true;

      # https://github.com/catppuccin/fzf

      # Catpuccin Frappe
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
        "selected-bg" = "#51576d";
        "border" = "#414559";
        "label" = "#c6d0f5";
      };

      # # Catpuccin Latte
      # colors = {
      #   "bg+" = "#ccd0da";
      #   bg = "#eff1f5";
      #   spinner = "#dc8a78";
      #   hl = "#d20f39";
      #   fg = "#4c4f69";
      #   header = "#d20f39";
      #   info = "#8839ef";
      #   pointer = "#dc8a78";
      #   marker = "#7287fd";
      #   "fg+" = "#4c4f69";
      #   prompt = "#8839ef";
      #   "hl+" = "#d20f39";
      #   "selected-bg" = "#bcc0cc";
      #   "border" = "#ccd0da";
      #   "label" = "#4c4f69";
      # };

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

