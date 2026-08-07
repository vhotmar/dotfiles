# The local MLX model table, shared by llm.nix and opencode.nix.
#
# Separate from llm.nix because that module is darwin-only, while the Lima
# guest still needs the repo ids and the endpoint to talk to the host's server.
{ config, lib, ... }:

{
  options.localLlm = {
    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        Address *clients* use to reach llm-serve. The server itself always
        binds loopback; the Lima guest overrides this with host.lima.internal,
        which its user-mode NAT forwards to the host's loopback.
      '';
    };

    port = lib.mkOption {
      type = lib.types.str;
      default = "8080";
      description = "Port llm-serve listens on.";
    };

    endpoint = lib.mkOption {
      type = lib.types.str;
      description = "OpenAI-compatible base URL, derived from host and port.";
    };

    defaultModel = lib.mkOption {
      type = lib.types.str;
      default = "big";
      description = "Alias used when none is given.";
    };

    # Attribute sets are alphabetical; help text and menus read better
    # largest-first.
    order = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "big"
        "gemma"
        "fast"
      ];
      description = "Display order for the aliases in ${"$"}{models}.";
    };

    models = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      description = ''
        alias -> { repo, family, label, size, desc, context }. `family` selects
        the sampling preset in llm.nix; `context` is what opencode plans
        against, not a server-side limit.
      '';
      default = {
        big = {
          repo = "mlx-community/Qwen3.6-35B-A3B-4bit";
          family = "qwen";
          label = "Qwen3.6-35B-A3B";
          size = "19.00 GB";
          desc = "35B MoE, 3B active";
          # ~80 KiB of KV cache per token, so 64k costs ~5 GiB on top of the
          # 19 GB of weights. 128k would be ~10.5 GiB and, with the 6 GB prompt
          # cache, crowds 48 GB.
          context = 65536;
        };
        # Served text-only: mlx-lm's gemma4.py drops the vision tower in
        # sanitize(), so it sits ~0.5 GB under its on-disk size. QAT weights are
        # trained for 4-bit and beat a plain post-training quant of the same
        # size; mlx-community/gemma-4-26b-a4b-it-4bit is the fallback if this
        # one ever misbehaves.
        gemma = {
          repo = "mlx-community/gemma-4-26B-A4B-it-qat-4bit";
          family = "gemma";
          label = "Gemma 4 26B-A4B";
          size = "15.64 GB";
          desc = "25B MoE, 3.8B active";
          # Sliding-window attention on 4 of every 5 layers makes its KV cache
          # far cheaper than the Qwen models', so this is headroom, not a limit.
          context = 65536;
        };
        fast = {
          repo = "mlx-community/Qwen3.5-9B-4bit";
          family = "qwen";
          label = "Qwen3.5-9B";
          size = " 5.54 GB";
          desc = "9B dense";
          context = 65536;
        };
      };
    };
  };

  config.localLlm.endpoint = lib.mkDefault "http://${config.localLlm.host}:${config.localLlm.port}/v1";
}
