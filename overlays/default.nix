{ inputs }:
let
  fenixOverlay = inputs.fenix.overlays.default;

  claudeCodeOverlay = inputs.claude-code-overlay.overlays.default;

  stablePackagesOverlay = final: prev: {
    stable = import inputs.nixpkgs-stable {
      inherit (final) system;

      config = {
        allowUnfree = true;
        allowBroken = true;
      };
    };
  };

  # Custom vpn-slice with newer commit
  vpnSliceOverlay = final: prev: {
    vpn-slice-vhotmar = prev.vpn-slice.overrideAttrs (
      _: p: {
        version = "git";
        src = prev.fetchFromGitHub {
          owner = "dlenski";
          repo = p.pname;
          rev = "4e26adbfd14de2be5e77933e96d353ea7d200107";
          sha256 = "sha256-x9Y36/wy0HhBc7tT6rG9ehGtzkoTPMj2jAOypX6yQRk";
        };
      }
    );
  };

  # yknotify: macOS notifications on YubiKey touch prompts
  yknotifyOverlay = final: prev: {
    yknotify = prev.buildGoModule {
      pname = "yknotify";
      version = "unstable-2025-02-12";
      src = prev.fetchFromGitHub {
        owner = "noperator";
        repo = "yknotify";
        rev = "0c773bdadedb137d02d95c79430fa5e0442c9950";
        hash = "sha256-AhTr3lzYS6z1XoqVC2IIdJoDVdWajrbGhOe20dVQrGQ=";
      };
      vendorHash = null;
      meta = {
        description = "Notify when YubiKey is waiting for a touch";
        homepage = "https://github.com/noperator/yknotify";
        license = prev.lib.licenses.mit;
        platforms = prev.lib.platforms.darwin;
      };
    };
  };

  # mlx with a working Metal backend.
  #
  # nixpkgs builds mlx from source, but the `metal` shader compiler ships only in
  # Xcode and can't run in the Nix sandbox, so that build silently has no GPU
  # backend (`mx.metal.is_available()` is False; inference pins one core and never
  # finishes instead of failing loudly). Upstream's prebuilt wheels split it in
  # two — `mlx` holds the bindings, `mlx-metal` holds libmlx.dylib + mlx.metallib
  # and installs *into* the mlx directory — so both unpack into one derivation.
  # See https://github.com/NixOS/nixpkgs/issues/390995
  #
  # Darwin-only because the wheels are Mach-O arm64, and nixpkgs' own mlx does
  # build on Linux: unguarded, the Linux configs would resolve to a macOS wheel
  # with no warning and fail at import.
  mlxMetalOverlay =
    final: prev:
    prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pyfinal: pyprev: {
          # mlx-lm 0.31.3 strands tool calls emitted inside <think> spans in the
          # reasoning field, hanging agent loops on thinking models (Qwen3.x).
          # Fixed by ml-explore/mlx-lm#1501, unreleased — drop this override once
          # nixpkgs ships anything newer than 0.31.3.
          mlx-lm = pyprev.mlx-lm.overridePythonAttrs (old: {
            version = "0.31.3-unstable-2026-07-08";
            src = prev.fetchFromGitHub {
              owner = "ml-explore";
              repo = "mlx-lm";
              rev = "86e9b35ea4db2c1bbaa6914c5fea56549d3e0dbd";
              hash = "sha256-scnFtN8oo7eucUzu01AF5bp0GJJ3DEPyOeZwmLKrhgA=";
            };
            # main needs sentencepiece at runtime; nixpkgs' 0.31.3 doesn't carry it.
            dependencies = (old.dependencies or [ ]) ++ [ pyfinal.sentencepiece ];
            # nixpkgs' disabledTestPaths is curated for 0.31.3 and doesn't fit
            # main; pythonImportsCheck still runs.
            doCheck = false;
            # nixpkgs' changelog interpolates src.tag, which a rev pin lacks.
            meta = old.meta // {
              changelog = "https://github.com/ml-explore/mlx-lm/commits/86e9b35ea4db2c1bbaa6914c5fea56549d3e0dbd";
            };
          });

          mlx =
            let
              metalWheel = prev.fetchurl {
                url = "https://files.pythonhosted.org/packages/dc/59/65d32520175379df33f107749193aa94ea9db069167a36a1a100ff689f62/mlx_metal-0.32.0-py3-none-macosx_26_0_arm64.whl";
                hash = "sha256-OvdqSY2EgE9mEZgASZ+dFD19/7CHig3Q18KEblhWX9c=";
              };
            in
            pyfinal.buildPythonPackage {
              pname = "mlx";
              version = "0.32.0";
              format = "wheel";

              # Both wheel URLs are content-addressed per file, so a python or mlx
              # bump needs each URL and hash re-pinned by hand — a computed cpXYZ
              # tag would only 404. The assert exists because a freethreaded
              # interpreter also reports "3.14": it would fetch this GIL wheel
              # happily and fail later on ABI mismatch.
              src =
                assert pyfinal.python.pythonVersion == "3.14";
                prev.fetchurl {
                  url = "https://files.pythonhosted.org/packages/c2/58/bd847d3fed65296573a4bb3399adde6934c0a718813b5636000d7d1b4063/mlx-0.32.0-cp314-cp314-macosx_26_0_arm64.whl";
                  hash = "sha256-I+g8jnSiMVZpbp+ZBdFqF7fSe1pZbBvA9yCpjfHFqt8=";
                };

              nativeBuildInputs = [ prev.unzip ];

              postInstall = ''
                unzip -o ${metalWheel} -d $out/${pyfinal.python.sitePackages}
              '';

              # postInstall satisfies the mlx-metal requirement, but the runtime
              # check runs in installPhase, before it. pythonImportsCheck below is
              # the real verification — it fails if the backend is missing.
              dontCheckRuntimeDeps = true;

              pythonImportsCheck = [ "mlx.core" ];

              meta = pyprev.mlx.meta // {
                description = "Array framework for Apple silicon (prebuilt wheel, Metal enabled)";
                platforms = [ "aarch64-darwin" ];
              };
            };
        })
      ];
    };
in
[
  fenixOverlay
  claudeCodeOverlay
  vpnSliceOverlay
  yknotifyOverlay
  mlxMetalOverlay
  stablePackagesOverlay
]
