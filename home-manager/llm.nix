# Local LLM inference through Apple MLX.
#
# mlx_lm.server calls load_default() from inside its generation worker rather
# than at startup, so `llm-serve` costs ~0 RAM until the first request lands.
{
  config,
  pkgs,
  lib,
  ...
}:

let
  models = {
    big = "mlx-community/Qwen3.6-35B-A3B-4bit"; # 19.00 GB — 35B MoE, 3B active
    fast = "mlx-community/Qwen3.5-9B-4bit"; # 5.54 GB — 9B dense
  };

  defaultModel = "big";

  host = "127.0.0.1";
  port = "8080";

  # Qwen's recommendations for the 3.5/3.6 family. presence_penalty (1.5 general,
  # 0.0 coding) has no CLI flag — pass it per-request in the JSON body.
  sampling = {
    general = "--temp 1.0 --top-p 0.95 --top-k 20 --min-p 0.0";
    coding = "--temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.0";
  };

  # Ceilings on everything that grows on top of the weights, so a long session
  # can't walk the machine into swap. mlx-lm parses the suffixes as decimal.
  promptCacheBytes = "6GB"; # total KV cache across cached conversations
  promptCacheCount = "4"; # distinct conversations kept warm (default 10)
  maxTokens = "32768"; # Qwen's recommended output cap
  cliMaxTokens = "4096"; # one-shot answers shouldn't run for twenty minutes

  # Stock is 32/8; see the note in llm-serve.
  decodeConcurrency = "4";
  promptConcurrency = "4";

  resolveModel = ''
    resolve_model() {
      case "''${1:-${defaultModel}}" in
        big)  echo "${models.big}"  ;;
        fast) echo "${models.fast}" ;;
        *)    echo "$1"             ;;
      esac
    }
  '';

  llm-serve = pkgs.writeShellApplication {
    name = "llm-serve";
    runtimeInputs = [ pkgs.python3Packages.mlx-lm ];
    text = ''
      ${resolveModel}

      preset="${sampling.general}"
      model=""

      while [ $# -gt 0 ]; do
        case "$1" in
          --coding) preset="${sampling.coding}"; shift ;;
          --help|-h)
            cat <<'EOF'
      llm-serve [big|fast|<hf-repo>] [--coding] [-- <extra mlx_lm.server args>]

      Starts an OpenAI-compatible server on http://${host}:${port}/v1.

      The model named here is only the default; each request's "model" field is
      resolved as a HF repo id and swaps it out, so only one is ever resident.

        big   ${models.big}  (19.00 GB)
        fast  ${models.fast}  ( 5.54 GB)
      EOF
            exit 0 ;;
          --) shift; break ;;
          # Without this, `llm-serve --port 9090` takes 9090 as the model name.
          -*) echo "llm-serve: unknown flag $1 (use -- to pass mlx_lm.server args)" >&2; exit 2 ;;
          *) model="$1"; shift ;;
        esac
      done

      repo="$(resolve_model "$model")"
      echo "llm-serve: default=$repo  endpoint=http://${host}:${port}/v1" >&2
      echo "llm-serve: weights load on first request, not now." >&2

      # Lowered from the stock 32/8: this GPU's resource_limit is 499000 *Metal
      # resources* (a count, not bytes — see `mx.device_info()`), and since
      # decode-concurrency preallocates that many KV slots, a 35B MoE leaves too
      # little headroom for a long generation — it dies with
      # "[metal::malloc] Resource limit exceeded".
      # shellcheck disable=SC2086
      exec mlx_lm.server \
        --model "$repo" \
        --host ${host} \
        --port ${port} \
        --max-tokens ${maxTokens} \
        --prompt-cache-size ${promptCacheCount} \
        --prompt-cache-bytes ${promptCacheBytes} \
        --decode-concurrency ${decodeConcurrency} \
        --prompt-concurrency ${promptConcurrency} \
        $preset \
        "$@"
    '';
  };

  # Routes through a running server so we don't load a second copy of the weights.
  llm = pkgs.writeShellApplication {
    name = "llm";
    runtimeInputs = [
      pkgs.python3Packages.mlx-lm
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      ${resolveModel}

      model=""
      think=false

      # Flag-only, never positional: `llm big deal, why is X` would otherwise
      # drop "big" from the prompt AND load the 19 GB model.
      while [ $# -gt 0 ]; do
        case "$1" in
          --big)    model="big";  shift ;;
          --fast)   model="fast"; shift ;;
          -m|--model)
            if [ $# -lt 2 ]; then echo "llm: $1 needs a value" >&2; exit 2; fi
            model="$2"; shift 2 ;;
          --think)  think=true;  shift ;;
          --help|-h)
            echo "llm [--big|--fast|-m REPO] [--think] <prompt...>" >&2
            echo "  one-shot completion; reads stdin when no prompt is given." >&2
            echo "  Uses the running llm-serve if there is one, else standalone." >&2
            echo "  Thinking is OFF by default; --think re-enables it." >&2
            exit 0 ;;
          --) shift; break ;;
          -*) echo "llm: unknown flag $1 (use -- to end flags)" >&2; exit 2 ;;
          *) break ;;
        esac
      done

      repo="$(resolve_model "$model")"

      if [ $# -eq 0 ]; then
        if [ -t 0 ]; then
          echo "llm: no prompt given and stdin is a terminal (see --help)" >&2
          exit 2
        fi
        prompt="$(cat)"
      else
        prompt="$*"
      fi

      if curl -sf -m 2 "http://${host}:${port}/v1/models" >/dev/null 2>&1; then
        # Thinking off by default: a one-shot answer would otherwise spend the
        # whole budget in <think> and return empty `content`.
        resp="$(
          jq -n --arg m "$repo" --arg p "$prompt" --argjson think "$think" \
            '{model:$m,
              messages:[{role:"user",content:$p}],
              max_tokens:${cliMaxTokens},
              chat_template_kwargs:{enable_thinking:$think}}' \
          | curl -sS -X POST "http://${host}:${port}/v1/chat/completions" \
              -H 'Content-Type: application/json' -d @-
        )"

        # Failures come back as a JSON {"error": ...} body, so a missing `content`
        # is ambiguous — thought past its budget, or generation died.
        if [ -z "$resp" ] || ! jq -e . >/dev/null 2>&1 <<<"$resp"; then
          echo "llm: no/invalid response from server" >&2
          exit 1
        fi
        if jq -e 'has("error")' >/dev/null 2>&1 <<<"$resp"; then
          echo "llm: server error: $(jq -r '.error | if type=="object" then (.message // tostring) else tostring end' <<<"$resp")" >&2
          exit 1
        fi

        content="$(jq -r '.choices[0].message.content // ""' <<<"$resp")"
        if [ -n "$content" ]; then
          printf '%s\n' "$content"
        else
          reason="$(jq -r '.choices[0].finish_reason // "?"' <<<"$resp")"
          echo "llm: empty content (finish_reason=$reason); model used the budget thinking" >&2
          jq -r '.choices[0].message.reasoning // ""' <<<"$resp" >&2
          exit 1
        fi
      else
        echo "llm: no server on ${port}, loading standalone (start one with llm-serve)" >&2
        # Match the server path so piping `llm` gives the same payload either way.
        mlx_lm.generate \
          --model "$repo" \
          --prompt "$prompt" \
          --max-tokens ${cliMaxTokens} \
          --verbose False \
          --chat-template-config "$(jq -nc --argjson t "$think" '{enable_thinking:$t}')" \
          ${sampling.general}
      fi
    '';
  };

  # Standalone by design — mlx_lm.chat's own prompt cache is what makes multi-turn
  # fast.
  llm-chat = pkgs.writeShellApplication {
    name = "llm-chat";
    runtimeInputs = [
      pkgs.python3Packages.mlx-lm
      pkgs.curl
    ];
    text = ''
      ${resolveModel}

      # Only consume $1 as the model when it is not a flag, so extra mlx_lm.chat
      # options (--system-prompt, --seed, ...) still reach "$@".
      model=""
      case "''${1:-}" in
        -*) ;;
        "") ;;
        # Not `[ $# -gt 0 ] && shift` — that returns 1 with no args and `set -e`
        # would kill the script.
        *) model="$1"; if [ $# -gt 0 ]; then shift; fi ;;
      esac
      repo="$(resolve_model "$model")"

      if curl -sf -m 2 "http://${host}:${port}/v1/models" >/dev/null 2>&1; then
        echo "llm-chat: warning — llm-serve is running; this loads a SECOND copy" >&2
        echo "          of the weights. Stop the server first to avoid swapping." >&2
      fi

      exec mlx_lm.chat \
        --model "$repo" \
        --max-kv-size 16384 \
        --max-tokens ${maxTokens} \
        --temp 1.0 \
        --top-p 0.95 \
        "$@"
    '';
  };

  llm-pull = pkgs.writeShellApplication {
    name = "llm-pull";
    runtimeInputs = [
      pkgs.python3Packages.huggingface-hub
      pkgs.python3Packages.mlx-lm
    ];
    text = ''
      case "''${1:-all}" in
        big)  repos=("${models.big}") ;;
        fast) repos=("${models.fast}") ;;
        all)  repos=("${models.fast}" "${models.big}") ;;
        # mlx_lm.manage raises CacheNotFound instead of reporting "nothing cached".
        list)
          mkdir -p "''${HF_HUB_CACHE:-''${HOME}/.cache/huggingface/hub}"
          exec mlx_lm.manage --scan
          ;;
        *)    repos=("$1") ;;
      esac

      for r in "''${repos[@]}"; do
        echo "==> $r"
        hf download "$r"
      done
    '';
  };
in
{
  home.packages = [
    pkgs.python3Packages.mlx-lm
    llm-serve
    llm
    llm-chat
    llm-pull
  ];

  programs.fish.shellAbbrs = {
    lls = "llm-serve";
    llc = "llm-chat";
  };
}
