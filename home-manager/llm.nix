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
  # mlx_lm.server's --temp/--top-k are only process-wide defaults, but any
  # request can name a model from either family, so `llm` also sends the
  # resolved family's numbers in the request body.
  sampling = {
    # Qwen's recommendations for the 3.5/3.6 family. presence_penalty (1.5
    # general, 0.0 coding) has no CLI flag — pass it per-request in the JSON body.
    qwen = {
      general = {
        temperature = 1.0;
        top_p = 0.95;
        top_k = 20;
        min_p = 0.0;
      };
      coding = {
        temperature = 0.6;
        top_p = 0.95;
        top_k = 20;
        min_p = 0.0;
      };
    };
    # Google's published defaults for Gemma 4. No separate coding preset: it
    # wants the same or *higher* temperature for code, the opposite of Qwen, so
    # --coding is deliberately a no-op here.
    gemma = {
      general = {
        temperature = 1.0;
        top_p = 0.95;
        top_k = 64;
      };
      coding = {
        temperature = 1.0;
        top_p = 0.95;
        top_k = 64;
      };
    };
  };

  inherit (config.localLlm) models defaultModel;
  modelOrder = config.localLlm.order;

  # Always loopback, never a LAN interface — the Lima guest reaches it through
  # its NAT gateway instead (see localLlm.host in llm-models.nix).
  host = "127.0.0.1";
  port = config.localLlm.port;

  # Ceilings on everything that grows on top of the weights, so a long session
  # can't walk the machine into swap. mlx-lm parses the suffixes as decimal.
  promptCacheBytes = "6GB"; # total KV cache across cached conversations
  promptCacheCount = "4"; # distinct conversations kept warm (default 10)
  maxTokens = "32768"; # Qwen's recommended output cap
  cliMaxTokens = "4096"; # one-shot answers shouldn't run for twenty minutes

  # Stock is 32/8; see the note in llm-serve.
  decodeConcurrency = "4";
  promptConcurrency = "4";

  flagFor = {
    temperature = "temp";
    top_p = "top-p";
    top_k = "top-k";
    min_p = "min-p";
  };

  renderFlags =
    preset:
    lib.concatStringsSep " " (
      lib.mapAttrsToList (k: v: "--${flagFor.${k}} ${builtins.toJSON v}") preset
    );

  # mlx_lm.chat only accepts --temp/--top-p, so the REPL samples a little wider
  # than the server does.
  chatKeys = [
    "temperature"
    "top_p"
  ];
  renderChatFlags = preset: renderFlags (lib.filterAttrs (k: _: lib.elem k chatKeys) preset);

  # `*[Gg]emma*` — lets an unlisted repo id still land on its family's numbers.
  familyGlob =
    family:
    let
      head = lib.substring 0 1 family;
    in
    "*[${lib.toUpper head}${head}]${lib.substring 1 (lib.stringLength family) family}*";

  samplingArms =
    render:
    lib.concatStringsSep "\n" (
      lib.concatLists (
        lib.mapAttrsToList (
          family: presets:
          lib.mapAttrsToList (
            name: preset: "    ${family}/${name}) echo ${lib.escapeShellArg (render preset)} ;;"
          ) presets
        ) sampling
      )
    );

  resolvers = ''
    resolve_model() {
      case "''${1:-${defaultModel}}" in
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (alias: m: "    ${alias}) echo \"${m.repo}\" ;;") models
    )}
        *) echo "$1" ;;
      esac
    }

    # Keyed on the resolved repo, so a request naming a repo id directly still
    # gets its family's numbers: exact matches first, then the family name
    # anywhere in the repo path, then ${defaultModel}'s family.
    resolve_family() {
      case "$1" in
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (_: m: "    ${m.repo}) echo ${m.family} ;;") models
    )}
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (family: _: "    ${familyGlob family}) echo ${family} ;;") sampling
    )}
        *) echo ${models.${defaultModel}.family} ;;
      esac
    }

    # $1 = family, $2 = preset (general|coding)
    sampling_flags() {
      case "$1/$2" in
    ${samplingArms renderFlags}
      esac
    }

    sampling_chat_flags() {
      case "$1/$2" in
    ${samplingArms renderChatFlags}
      esac
    }

    sampling_json() {
      case "$1/$2" in
    ${samplingArms builtins.toJSON}
      esac
    }
  '';

  pad = width: s: s + lib.concatStrings (lib.genList (_: " ") (width - lib.stringLength s));

  helpModels = lib.concatStringsSep "\n" (
    map (
      alias:
      let
        m = models.${alias};
      in
      "  ${pad 6 alias}${m.repo}  (${m.size}, ${m.desc})"
    ) modelOrder
  );

  aliasList = lib.concatStringsSep "|" modelOrder;

  llm-serve = pkgs.writeShellApplication {
    name = "llm-serve";
    runtimeInputs = [ pkgs.python3Packages.mlx-lm ];
    text = ''
      ${resolvers}

      preset=general
      model=""

      while [ $# -gt 0 ]; do
        case "$1" in
          --coding) preset=coding; shift ;;
          --help|-h)
            cat <<'EOF'
      llm-serve [${aliasList}|<hf-repo>] [--coding] [-- <extra mlx_lm.server args>]

      Starts an OpenAI-compatible server on http://${host}:${port}/v1.

      The model named here is only the default; each request's "model" field is
      resolved as a HF repo id and swaps it out, so only one is ever resident.

      ${helpModels}

      --coding only shifts the Qwen models (temp 1.0 -> 0.6); Gemma 4 wants the
      same temperature either way.
      EOF
            exit 0 ;;
          --) shift; break ;;
          # Without this, `llm-serve --port 9090` takes 9090 as the model name.
          -*) echo "llm-serve: unknown flag $1 (use -- to pass mlx_lm.server args)" >&2; exit 2 ;;
          *) model="$1"; shift ;;
        esac
      done

      repo="$(resolve_model "$model")"
      family="$(resolve_family "$repo")"
      flags="$(sampling_flags "$family" "$preset")"

      echo "llm-serve: default=$repo  endpoint=http://${host}:${port}/v1" >&2
      echo "llm-serve: sampling ($family/$preset): $flags" >&2
      echo "llm-serve: weights load on first request, not now." >&2

      # Concurrency is lowered from the stock 32/8: this GPU's resource_limit is
      # 499000 *Metal resources* (a count, not bytes — see `mx.device_info()`),
      # and since decode-concurrency preallocates that many KV slots, a 35B MoE
      # leaves too little headroom for a long generation — it dies with
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
        $flags \
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
      ${resolvers}

      model=""
      think=false

      # Flag-only, never positional: `llm big deal, why is X` would otherwise
      # drop "big" from the prompt AND load the 19 GB model.
      while [ $# -gt 0 ]; do
        case "$1" in
      ${lib.concatStringsSep "\n" (
        map (alias: "    ${pad 10 "--${alias})"} model=\"${alias}\"; shift ;;") modelOrder
      )}
          -m|--model)
            if [ $# -lt 2 ]; then echo "llm: $1 needs a value" >&2; exit 2; fi
            model="$2"; shift 2 ;;
          --think)  think=true;  shift ;;
          --help|-h)
            echo "llm [--${lib.concatStringsSep "|--" modelOrder}|-m REPO] [--think] <prompt...>" >&2
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
      family="$(resolve_family "$repo")"

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
                --argjson s "$(sampling_json "$family" general)" \
            '{model:$m,
              messages:[{role:"user",content:$p}],
              max_tokens:${cliMaxTokens},
              chat_template_kwargs:{enable_thinking:$think}} + $s' \
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
        # shellcheck disable=SC2046
        mlx_lm.generate \
          --model "$repo" \
          --prompt "$prompt" \
          --max-tokens ${cliMaxTokens} \
          --verbose False \
          --chat-template-config "$(jq -nc --argjson t "$think" '{enable_thinking:$t}')" \
          $(sampling_flags "$family" general)
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
      ${resolvers}

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
      family="$(resolve_family "$repo")"

      if curl -sf -m 2 "http://${host}:${port}/v1/models" >/dev/null 2>&1; then
        echo "llm-chat: warning — llm-serve is running; this loads a SECOND copy" >&2
        echo "          of the weights. Stop the server first to avoid swapping." >&2
      fi

      # shellcheck disable=SC2046
      exec mlx_lm.chat \
        --model "$repo" \
        --max-kv-size 16384 \
        --max-tokens ${maxTokens} \
        $(sampling_chat_flags "$family" general) \
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
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (alias: m: "  ${pad 7 "${alias})"} repos=(\"${m.repo}\") ;;") models
      )}
        # Smallest first, so a slow link still leaves something usable early.
        all)  repos=(${
          lib.concatStringsSep " " (map (alias: "\"${models.${alias}.repo}\"") (lib.reverseList modelOrder))
        }) ;;
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
  imports = [ ./llm-models.nix ];

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
