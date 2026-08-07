* Home config

** Updates

```sh
nix flake update
sudo darwin-rebuild switch --flake ~/main/dotfiles/nix#macbook # or some other path
```

** Local LLM (macOS only)

Apple MLX, configured in =home-manager/llm.nix=. Nothing occupies memory until a
server takes its first request.

- =llm-serve [big|gemma|fast]= — OpenAI-compatible server on http://127.0.0.1:8080/v1
- =llm [--big|--gemma|--fast] ...= — one-shot; reuses a running server
- =llm-chat [big|gemma|fast]= — REPL, loads its own copy of the weights
- =llm-pull [all|list]= — download / list cached models

| alias   | model                    | size     | for                          |
|---------+--------------------------+----------+------------------------------|
| =big=   | Qwen3.6-35B-A3B          | 19.00 GB | agentic coding, tool loops   |
| =gemma= | Gemma 4 26B-A4B (QAT)    | 15.64 GB | general chat, lighter        |
| =fast=  | Qwen3.5-9B               |  5.54 GB | quick one-shots              |

Only one is resident at a time; a request's =model= field swaps it. Any HF repo
id works in place of an alias.

=big= is the better coder by a wide margin (SWE-bench Verified 73.4 vs 52.0, MCP
tool use 37.0 vs 18.1) and the stronger model overall. =gemma= is 3.4 GB lighter
at a similar decode speed, so it is the one to reach for when =big= is crowding
memory. Sampling differs per family (Qwen top-k 20, Gemma top-k 64) and =llm=
sends the right numbers per request regardless of how the server was started;
=--coding= only lowers temperature for the Qwen models.

Gemma 4's checkpoint is multimodal, but mlx-lm strips the vision tower and
serves it text-only.

*** opencode

Configured in =home-manager/opencode.nix=, defaulting to =mlx/big= (Qwen3.6).
Switch models inside opencode with =/models=; =mlx/gemma= and =mlx/fast= are
also listed.

Start =llm-serve= first — opencode has no cloud fallback, so it fails rather
than quietly reaching for a hosted model.

The same config works inside the kdev Lima VM. The server binds only the host's
loopback and is *not* exposed to the LAN; Lima's user-mode NAT forwards
=host.lima.internal= to that loopback, which is the only thing =lima.nix=
overrides. Both sides share the model table in =home-manager/llm-models.nix=.

=small_model= is deliberately the same model as =model=: mlx_lm.server keeps one
set of weights resident, so a different small model would evict 19 GB and reload
it for every title generation. The same applies to switching models mid-session.
