#!/usr/bin/env nu

let rg_prefix = "rg --column --line-number --no-heading --color=always --smart-case "

echo $env.SHELL

# (fzf
#   --ansi --disabled --query ""
#   --bind $"start:reload:($rg_prefix) {q}"
#   --bind $"change:reload:sleep 0.1; ($rg_prefix) {q} || true")
