# opencode pointed at the local MLX server.
#
# Imported on the macOS host and inside the Lima guest; only localLlm.host
# differs between them (see lima.nix).
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.localLlm;

  # opencode addresses a model as "<provider>/<key>", so the keys stay the `llm`
  # CLI's short aliases; `id` carries the HF repo id mlx_lm.server wants.
  toModel = alias: m: {
    id = m.repo;
    name = "${m.label} (local)";
    tool_call = true;
    reasoning = true;
    temperature = true;
    attachment = false;
    limit = {
      context = m.context;
      # Matches llm-serve's --max-tokens.
      output = 32768;
    };
  };
in
{
  imports = [ ./llm-models.nix ];

  programs.opencode = {
    enable = true;

    settings = {
      "$schema" = "https://opencode.ai/config.json";

      model = "mlx/${cfg.defaultModel}";

      # Deliberately the same model: mlx_lm.server keeps exactly one set of
      # weights resident, so a different small_model would evict 19 GB and
      # reload it for every title generation.
      small_model = "mlx/${cfg.defaultModel}";

      autoupdate = false;
      share = "disabled";

      provider.mlx = {
        npm = "@ai-sdk/openai-compatible";
        name = "Local MLX";
        options = {
          baseURL = cfg.endpoint;
          # The first request after llm-serve starts pays the full read of the
          # weights from disk — minutes, not seconds.
          timeout = 600000;
        };
        models = lib.mapAttrs toModel cfg.models;
      };
    };
  };
}
