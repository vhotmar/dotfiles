* Home config

** Updates

```sh
nix flake update
sudo darwin-rebuild switch --flake ~/main/dotfiles/nix#macbook # or some other path
```

** Local LLM (macOS only)

Apple MLX, configured in =home-manager/llm.nix=. Nothing occupies memory until a
server takes its first request.

- =llm-serve [big|fast]= — OpenAI-compatible server on http://127.0.0.1:8080/v1
- =llm [--big|--fast] ...= — one-shot; reuses a running server
- =llm-chat [big|fast]= — REPL, loads its own copy of the weights
- =llm-pull [all|list]= — download / list cached models

=big= is Qwen3.6-35B-A3B (19 GB MoE), =fast= is Qwen3.5-9B (5.5 GB). Only one is
resident at a time; a request's =model= field swaps it.
